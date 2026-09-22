# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="8"
K_SECURITY_UNSUPPORTED="1"
K_NOSETEXTRAVERSION="1"
K_NODRYRUN="yes"

inherit kernel-2 unpacker
detect_version
detect_arch

# Forked from ::gentoo's zen-sources-7.1.5 and bumped: the tree still
# carries only 7.1.5, and the live images want v7.2.7-zen1 (upstream
# release 2026-09-21; the 7.1 series went EOL with 7.1.13 on 2026-09-02).
# K_GENPATCHES_VER follows the genpatches that CARRIES the stable patch --
# there is no patch-7.2.7.xz in SRC_URI, the tree is linux-7.2.tar.xz plus
# genpatches 1000..1006_linux-7.2.*.patch, so 7.2.N needs genpatches-7.2-(N+1)
# (7.2.7 -> 8, which is also what gentoo-sources would use). ::gentoo's
# gentoo-sources stops at 7.2.6 for now; -8 is published and does contain
# 1006_linux-7.2.7.patch.
DESCRIPTION="The Zen Kernel Live Sources"
HOMEPAGE="https://github.com/zen-kernel"

# Needed for zstd compression of the patch
BDEPEND="$(unpacker_src_uri_depends)"

ZEN_VER=1
ZEN_URI="https://github.com/zen-kernel/zen-kernel/releases/download/v${PV}-zen${ZEN_VER}/linux-v${PV}-zen${ZEN_VER}.patch.zst"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI} ${ZEN_URI}"

KEYWORDS="~amd64 ~arm64 ~x86"

UNIPATCH_LIST="${WORKDIR}/linux-v${PV}-zen${ZEN_VER}.patch"
UNIPATCH_EXCLUDE="2700"

K_EXTRAEINFO="For more info on zen-sources, and for how to report problems, see: \
${HOMEPAGE}, also go to #zen-sources on oftc"

src_unpack() {
	unpacker "linux-v${PV}-zen${ZEN_VER}.patch.zst"
	kernel-2_src_unpack
}

pkg_setup() {
	ewarn
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the zen developers directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn
	kernel-2_pkg_setup
}

src_prepare() {
	default
	kernel-2_src_prepare
}

src_install() {
	rm "${WORKDIR}/linux-v${PV}-zen${ZEN_VER}.patch" || die
	kernel-2_src_install
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
