# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev

DESCRIPTION="Udev rules granting seat users access to Trezor hardware wallets"
HOMEPAGE="https://trezor.io/learn/security-privacy/udev-rules"
S="${WORKDIR}"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="acct-group/plugdev"

src_install() {
	udev_dorules "${FILESDIR}"/51-trezor.rules
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
