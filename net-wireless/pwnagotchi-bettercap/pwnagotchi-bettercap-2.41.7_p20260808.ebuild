# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

# NOT upstream bettercap, and not even this fork's master: jayofelony's
# "pcapng" BRANCH, which is what net-wireless/pwnagotchi's image builds. Its
# extra commits keep a handshake pcapng file's section open across bettercap
# restarts, where upstream starts a fresh section each time and pwnagotchi's
# handshake accounting mis-reads the result.
#
# Hence the package name: upstream bettercap is at 2.41.7 and diverging, so
# net-analyzer/bettercap stays free for a real one. PV comes from the branch
# itself -- core/banner.go says Version = "2.41.7-pcapng", so the base is 2.41.7
# despite the fork's newest git TAG being the much older v2.40.1 on master.
MY_COMMIT="16a9918685025642a9920aee9c8f1fd48f40cd32"
MY_PN="bettercap"

DESCRIPTION="bettercap fork (pcapng branch) that net-wireless/pwnagotchi drives"
HOMEPAGE="
	https://github.com/jayofelony/bettercap
	https://www.bettercap.org/
"
SRC_URI="
	https://github.com/jayofelony/${MY_PN}/archive/${MY_COMMIT}.tar.gz
		-> ${P}.gh.tar.gz
"
S="${WORKDIR}/${MY_PN}-${MY_COMMIT}"

LICENSE="GPL-3"
# Go module dependencies
LICENSE+=" Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# gopacket's pcap binding is cgo against libpcap; libusb backs the HID/NRF24
# modules and libnetfilter_queue the packet-proxy ones.
DEPEND="
	dev-libs/libusb:1
	net-libs/libnetfilter_queue
	net-libs/libpcap
"
RDEPEND="${DEPEND}"
BDEPEND=">=dev-lang/go-1.25.0"

# Installs /usr/bin/bettercap under the real tool's name, because that is what
# it is and what the caplets and pwnagotchi's launcher invoke. Add a blocker
# here if net-analyzer/bettercap ever lands in a repo you have enabled.
RESTRICT="network-sandbox test"

src_compile() {
	# 'make' would rebuild network/manuf.go first. It is already in the tarball
	# (2 MB of OUI tables) and make_manuf.py only reads local CSVs, so building
	# the binary directly skips a python3 BDEPEND for what would be a no-op.
	[[ -f network/manuf.go ]] ||
		die "network/manuf.go is not pre-generated any more -- restore the 'make resources' step"
	ego build -o ${MY_PN} .
}

src_install() {
	dobin ${MY_PN}
	# Upstream's 'make install' only mkdir's this; the caplets themselves are a
	# separate repo -- net-wireless/pwnagotchi-caplets.
	keepdir /usr/share/${MY_PN}/caplets
	dodoc README.md
}

pkg_postinst() {
	elog "This installs /usr/bin/bettercap from jayofelony's pcapng branch,"
	elog "packaged for net-wireless/pwnagotchi. It reports itself as"
	elog "2.41.7-pcapng, but it is NOT upstream 2.41.7 -- do not treat this as"
	elog "a general bettercap install."
	elog
	elog "The pwnagotchi-auto and pwnagotchi-manual caplets it is started with"
	elog "come from net-wireless/pwnagotchi-caplets."
}
