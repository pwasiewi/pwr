# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic git-r3 linux-info shell-completion

DESCRIPTION="Disposable, confined development environments for AI coding agents"
HOMEPAGE="https://github.com/h5i-dev/h5i"
EGIT_REPO_URI="https://github.com/h5i-dev/${PN}.git"

LICENSE="Apache-2.0"
SLOT="0"
# No KEYWORDS for live ebuild.

IUSE="+web containers"

PROPERTIES="live"
RESTRICT="network-sandbox test"

RDEPEND="
	dev-libs/openssl:=
	containers? ( app-containers/podman )
"
DEPEND="${RDEPEND}"
BDEPEND="
	|| ( >=dev-lang/rust-1.85 >=dev-lang/rust-bin-1.85 )
	virtual/pkgconfig
	web? ( net-libs/nodejs[npm] )
"

CONFIG_CHECK="~SECURITY_LANDLOCK ~SECCOMP_FILTER ~USER_NS ~NET_NS ~PID_NS"
ERROR_SECURITY_LANDLOCK="CONFIG_SECURITY_LANDLOCK is off — the 'process' and 'supervised' tiers will fail. Note it must ALSO be listed in CONFIG_LSM to be active."

# Everything below is identical to the released ebuild; see h5i-0.3.1.ebuild
# for why LTO is filtered (ring's asm vs rustc's lld), why OPENSSL_NO_VENDOR
# is set, and why libgit2 stays vendored.
src_configure() {
	filter-lto
	export OPENSSL_NO_VENDOR=1
}

src_compile() {
	local features=()
	use web || features+=( --no-default-features )

	cargo build --release --bin h5i "${features[@]}" || die "cargo build failed"
}

src_install() {
	dobin target/release/h5i

	# main may carry a man page that has drifted from the binary; regenerate
	# rather than trusting the committed one, since upstream only refreshes it
	# at release time via scripts/gen_man.sh.
	if [[ -f man/man1/h5i.1 ]]; then
		doman man/man1/h5i.1
	fi

	local shell
	for shell in bash zsh fish; do
		target/release/h5i completion "${shell}" > "${T}"/h5i.${shell} ||
			die "generating ${shell} completion failed"
	done
	newbashcomp "${T}"/h5i.bash h5i
	newzshcomp "${T}"/h5i.zsh _h5i
	newfishcomp "${T}"/h5i.fish h5i.fish

	if [[ -d skills/h5i ]]; then
		insinto /usr/share/${PN}/skills
		doins -r skills/h5i/.
	fi

	dodoc README.md MANUAL.md ROADMAP.md SECURITY.md
}

pkg_postinst() {
	elog "Confinement tiers and what each one needs beyond this package:"
	elog ""
	elog "  workspace   nothing — a separate git worktree, no confinement"
	elog "  process     CONFIG_SECURITY_LANDLOCK=y AND 'landlock' present in"
	elog "              CONFIG_LSM (or lsm= on the kernel command line)."
	elog "              Compiled but unlisted means inert."
	elog "  supervised  the above, plus net-firewall/nftables for the egress"
	elog "              allowlist"
	elog "  container   USE=containers (rootless Podman)"
	elog "  microvm     /dev/kvm plus the microsandbox runtime, which is not"
	elog "              packaged here"
	elog ""
	elog "Check the running kernel with:  cat /sys/kernel/security/lsm"
	elog ""
	if ! use web; then
		elog "Built with USE=-web: the 'h5i ui' box console is not included."
		elog ""
	fi
	elog "A Claude Code skill for h5i is installed in"
	elog "  /usr/share/${PN}/skills/"
}
