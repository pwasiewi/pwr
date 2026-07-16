# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 go-module

DESCRIPTION="Open-source multi-port IP-KVM daemon"
HOMEPAGE="https://github.com/tobychui/DezKVM"
EGIT_REPO_URI="https://github.com/tobychui/DezKVM.git"
EGIT_BRANCH="main"

EGIT_CHECKOUT_DIR="${WORKDIR}/${P}"
S="${EGIT_CHECKOUT_DIR}/src/dezkvmd"

LICENSE="GPL-3 BSD MIT"
SLOT="0"

RDEPEND="
	media-libs/libv4l
	media-sound/alsa-utils
"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	ego build -o "${T}/dezkvmd" . || die "failed to build dezkvmd"
}

src_install() {
	dobin "${T}/dezkvmd"
	dosym dezkvmd /usr/bin/dezkvm
	dodoc "${EGIT_CHECKOUT_DIR}/README.md"
}

pkg_postinst() {
	elog "Run dezkvmd -h to list the available modes and options."
	elog "The compatibility command dezkvm points to dezkvmd."
}
