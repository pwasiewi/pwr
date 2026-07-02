# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module git-r3 systemd

DESCRIPTION="eBPF-based Security and Observability tool for Linux"
HOMEPAGE="https://github.com/aquasecurity/tracee"

EGIT_REPO_URI="https://github.com/aquasecurity/tracee.git"
# libbpf submodule dostarczamy jako tarball w SRC_URI — nie przez git-r3

LIBBPF_PV="1.7.0"
# geyslan/libbpfgo adds m.BTFFD() needed for kernel ≥6.9 fix (issue #5330, PR #5337)
LIBBPFGO_PKG="github.com/geyslan/libbpfgo"
LIBBPFGO_VER="v0.1.2-0.20260617155751-5e7cdf434a37"
LIBBPFGO_REPLACE="${LIBBPFGO_PKG} ${LIBBPFGO_VER}"
# go.sum hashes from PR #5337 go.sum diff
LIBBPFGO_H1="h1:g6PFYBi41ITOfkpO5xEaQuUphfrFf3UqmP76ZqRSmMo="
LIBBPFGO_GOMOD_H1="h1:veHe4u3xEpl0TBV+wX0AFJWOsnteNPOhNklRbYf3d+k="

SRC_URI="https://github.com/libbpf/libbpf/archive/refs/tags/v${LIBBPF_PV}.tar.gz
	-> libbpf-${LIBBPF_PV}.tar.gz"

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

	# Rozpakuj libbpf v1.7.0 do miejsca submodułu (zanim Makefile spróbuje go sklonować)
	mkdir -p "${S}/3rdparty/libbpf" || die
	tar xzf "${DISTDIR}/libbpf-${LIBBPF_PV}.tar.gz" \
		--strip-components=1 \
		-C "${S}/3rdparty/libbpf" || die

	# Redirect aquasecurity/libbpfgo → geyslan/libbpfgo which adds m.BTFFD().
	# BTF_GET_FD_BY_ID requires CAP_SYS_ADMIN in kernel ≥6.9; m.BTFFD() avoids
	# the syscall entirely by reusing the already-open BPF module fd.
	sed -i '/replace github\.com\/aquasecurity\/libbpfgo/d' "${S}/go.mod" || die
	echo "replace github.com/aquasecurity/libbpfgo => ${LIBBPFGO_REPLACE}" \
		>> "${S}/go.mod" || die

	# go.sum must be updated before go mod vendor: remove old aquasecurity/libbpfgo
	# hashes and add geyslan/libbpfgo hashes (from PR #5337 go.sum diff).
	sed -i '/^github\.com\/aquasecurity\/libbpfgo /d' "${S}/go.sum" || die
	printf '%s\n' \
		"${LIBBPFGO_PKG} ${LIBBPFGO_VER} ${LIBBPFGO_H1}" \
		"${LIBBPFGO_PKG} ${LIBBPFGO_VER}/go.mod ${LIBBPFGO_GOMOD_H1}" \
		>> "${S}/go.sum" || die

	go-module_live_vendor
}

src_prepare() {
	# Makefile wywołuje 'git submodule update --init 3rdparty/libbpf' w fazie kompilacji,
	# ale libbpf jest już rozpakowane z tarballa — usuwamy te wywołania
	sed -i '/git submodule/d' Makefile || die

	# PR #5337 (geyslan, kernel ≥6.9): zamień GetBTFFDByID (wymaga CAP_SYS_ADMIN)
	# na m.BTFFD() (używa już otwartego fd BPF modułu, bez dodatkowych uprawnień)
	sed -i 's|bpf\.GetBTFFDByID(info\.BTFID)|m.BTFFD()|g' \
		pkg/policy/ebpf.go || die

	default
}

src_compile() {
	# BTFHUB=0: pomijamy pobieranie archiwum BTF (BTF wbudowany w zen-kernel)
	emake tracee BTFHUB=0
}

src_install() {
	dobin dist/tracee

	insinto /usr/share/tracee
	doins dist/tracee.bpf.o

	# Systemd service files — dwa tryby (Conflicts= między sobą)
	if use systemd; then
		systemd_dounit "${FILESDIR}"/tracee.service
		systemd_dounit "${FILESDIR}"/tracee-forensic.service
	fi

	# Policy YAML — tryb minimalny i śledczy
	insinto /etc/tracee
	doins "${FILESDIR}"/policy-minimal.yaml
	doins "${FILESDIR}"/policy-forensic.yaml

	# Logrotate — rotacja daily, 90 dni, sha256sum po rotacji
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/tracee.logrotate tracee

	dodoc Readme.md
}

pkg_postinst() {
	elog "Tracee wymaga BTF w kernelu (CONFIG_DEBUG_INFO_BTF=y)."
	elog ""
	elog "Tryb minimalny (always-on, ~160 MB RAM):"
	elog "  systemctl enable --now tracee"
	elog ""
	elog "Tryb śledczy (incident response, 1-3% CPU, 10-100 MB/dzień):"
	elog "  systemctl stop tracee && systemctl start tracee-forensic"
	elog ""
	elog "Policy YAML: /etc/tracee/policy-{minimal,forensic}.yaml"
	elog "Logi: /var/log/tracee/{detections,forensic}.json"
}
