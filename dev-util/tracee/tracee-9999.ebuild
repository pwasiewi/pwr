# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module git-r3 systemd

DESCRIPTION="eBPF-based Security and Observability tool for Linux"
HOMEPAGE="https://github.com/aquasecurity/tracee"

EGIT_REPO_URI="https://github.com/aquasecurity/tracee.git"
# The 3rdparty/libbpf submodule is fetched by git-r3 at the commit upstream pins.
# The kernel >=6.9 BTF fix (issue #5330, PR #5337) is merged upstream since
# 2026-07-30, so no libbpfgo redirect or source sed is needed any more.

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS=""
IUSE="systemd"

BDEPEND="
	>=dev-lang/go-1.26.0
	>=llvm-core/clang-14:*
	>=llvm-core/llvm-14:*
	virtual/libelf
	sys-libs/zlib
	sys-kernel/linux-headers
"

RDEPEND="
	systemd? ( sys-apps/systemd )
"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_prepare() {
	# The Makefile runs 'git submodule update' at compile time; the network-less
	# build dir has no .git and git-r3 already checked the submodule out.
	sed -i '/git submodule/d' Makefile || die

	default
}

src_compile() {
	# BTFHUB=0: skip the BTF archive download (zen-kernel has built-in BTF)
	emake tracee BTFHUB=0
}

src_install() {
	dobin dist/tracee

	insinto /usr/share/tracee
	doins dist/tracee.bpf.o

	# Systemd service files: two modes with Conflicts= on each other
	if use systemd; then
		systemd_dounit "${FILESDIR}"/tracee.service
		systemd_dounit "${FILESDIR}"/tracee-forensic.service
	fi

	# Policy YAML: minimal and forensic modes
	insinto /etc/tracee
	doins "${FILESDIR}"/policy-minimal.yaml
	doins "${FILESDIR}"/policy-forensic.yaml

	# Logrotate: daily, 90 days, sha256sum after rotation
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/tracee.logrotate tracee

	dodoc Readme.md
}

pkg_postinst() {
	elog "Tracee needs kernel BTF (CONFIG_DEBUG_INFO_BTF=y)."
	elog ""
	elog "Minimal mode (always-on, ~160 MB RAM):"
	elog "  systemctl enable --now tracee"
	elog ""
	elog "Forensic mode (incident response, 1-3% CPU, 10-100 MB/day):"
	elog "  systemctl stop tracee && systemctl start tracee-forensic"
	elog ""
	elog "Policy YAML: /etc/tracee/policy-{minimal,forensic}.yaml"
	elog "Logs: /var/log/tracee/{detections,forensic}.json"
}
