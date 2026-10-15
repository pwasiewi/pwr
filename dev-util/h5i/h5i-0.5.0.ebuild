# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic linux-info shell-completion

DESCRIPTION="Disposable, confined development environments for AI coding agents"
HOMEPAGE="https://github.com/h5i-dev/h5i"
SRC_URI="https://github.com/h5i-dev/${PN}/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.gh.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

# Upstream's default feature set (web browser ytdlp identity) turns 0.5 into a
# web red-team workbench. Here the package is a sandbox for agent and skill
# tests, so everything beyond 'h5i box' is opt-in and off by default:
#   web       the 'h5i ui' box console; crates/h5i-core/build.rs runs npm + vite
#   browser   the embedded rendering engine, 'h5i browser' and its proxy;
#             upstream's 'identity' and 'ytdlp' features ride on it
#   containers  the 'container' tier (rootless Podman)
# 'h5i box' is not feature-gated (src/lib.rs), so a no-USE build keeps it.
IUSE="browser containers web"

# Cargo resolves and downloads the whole crate graph at build time, and with
# USE=web so does npm. Same approach as sci-ml/kokoros — no vendored CRATES
# list, so the sandbox has to allow network.
RESTRICT="network-sandbox test"

# slirp4netns: the supervised tier's egress allowlist runs inside the box's
# netns and refuses to start without it (h5i-sandbox supervisor.rs
# egress_preflight); pasta is not accepted. Supervised is the tier an agent
# box needs, so it is a hard dependency, not a USE flag.
RDEPEND="
	app-containers/slirp4netns
	containers? ( app-containers/podman )
"
DEPEND="${RDEPEND}"
# 0.4 moved TLS to rustls; aws-lc-sys (rustls' default provider) builds its C
# with cmake. libgit2 and zlib stay vendored, see the 0.3.1 ebuild for why.
BDEPEND="
	|| ( >=dev-lang/rust-bin-1.85 >=dev-lang/rust-1.85 )
	dev-build/cmake
	virtual/pkgconfig
	web? ( net-libs/nodejs[npm] )
"

# Landlock is what the 'process' and 'supervised' tiers are built on, and h5i
# fails closed rather than silently downgrading. Warn rather than die: the
# workspace/container/microvm tiers do not need it, and this also has to merge
# inside an image chroot whose kernel is not the running one.
CONFIG_CHECK="~SECURITY_LANDLOCK ~SECCOMP_FILTER ~USER_NS ~NET_NS ~PID_NS"
ERROR_SECURITY_LANDLOCK="CONFIG_SECURITY_LANDLOCK is off — the 'process' and 'supervised' tiers will fail. Note it must ALSO be listed in CONFIG_LSM to be active."

src_configure() {
	# ring/aws-lc C and assembly get the ebuild's CFLAGS; on an LTO profile
	# that is GCC LTO IR which rustc's linker cannot read (undefined
	# ring_core_* symbols at link time).
	filter-lto
}

src_compile() {
	local features=() feats=()
	use browser && feats+=( browser identity ytdlp )
	use web && feats+=( web )
	if [[ ${#feats[@]} -gt 0 ]]; then
		local IFS=,
		features=( --no-default-features --features "${feats[*]}" )
	else
		features=( --no-default-features )
	fi
	# The web build runs npm; without USE=web make sure no stray env asks for it.
	use web || export H5I_SKIP_WEB_BUILD=1

	cargo build --release --locked --bin h5i "${features[@]}" ||
		die "cargo build failed"
}

src_install() {
	dobin target/release/h5i

	doman docs/man/man1/h5i.1

	# Completions come from the binary itself (clap_complete).
	local shell
	for shell in bash zsh fish; do
		target/release/h5i completion "${shell}" > "${T}"/h5i.${shell} ||
			die "generating ${shell} completion failed"
	done
	newbashcomp "${T}"/h5i.bash h5i
	newzshcomp "${T}"/h5i.zsh _h5i
	newfishcomp "${T}"/h5i.fish h5i.fish

	# Upstream's Claude Code skill: shipped as reference only, never into
	# ~/.claude. It covers the browser/red-team lanes too.
	insinto /usr/share/${PN}/skills
	doins -r skills/h5i/.

	dodoc README.md SECURITY.md docs/MANUAL.md docs/ROADMAP.md
}

pkg_postinst() {
	elog "Confinement tiers and what each one needs beyond this package:"
	elog "  workspace   nothing — a separate git worktree, no confinement"
	elog "  process     CONFIG_SECURITY_LANDLOCK=y AND 'landlock' in CONFIG_LSM"
	elog "  supervised  the above; egress allowlist via slirp4netns (pulled in)"
	elog "  container   USE=containers (rootless Podman)"
	elog "  microvm     /dev/kvm plus the microsandbox runtime (not packaged)"
	elog "Check the running kernel with:  cat /sys/kernel/security/lsm"
	use browser || elog "Built without USE=browser: no h5i browser command."
	use web || elog "Built without USE=web: no h5i ui command."
}
