# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

# jayofelony's fork, which is the one net-wireless/pwnagotchi talks to and the
# only one still moving: upstream evilsocket/pwngrid stopped at v1.10.3 in 2019
# and last saw a commit in 2023. Named for the fork rather than taking
# net-wireless/pwngrid, which belongs to upstream if anyone ever packages it.
MY_PN="pwngrid"

DESCRIPTION="pwngrid fork (jayofelony) -- peer mesh protocol used by pwnagotchi"
HOMEPAGE="https://github.com/jayofelony/pwngrid"
SRC_URI="
	https://github.com/jayofelony/${MY_PN}/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="GPL-3"
# Go module dependencies
LICENSE+=" Apache-2.0 BSD BSD-2 ISC MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# gopacket's pcap binding is cgo against libpcap
DEPEND="net-libs/libpcap"
RDEPEND="${DEPEND}"
BDEPEND=">=dev-lang/go-1.25.0"

RESTRICT="network-sandbox test"

src_compile() {
	ego build -o ${MY_PN} ./cmd/${MY_PN}
}

src_install() {
	dobin ${MY_PN}
	# Upstream's 'make install' writes straight into /usr/local/bin, drops a
	# config into /etc/pwngrid and runs systemctl daemon-reload -- none of which
	# belongs in src_install. Service files here are ours.
	systemd_dounit "${FILESDIR}"/${MY_PN}-peer.service
	newinitd "${FILESDIR}"/${MY_PN}-peer.initd ${MY_PN}-peer
	newconfd "${FILESDIR}"/${MY_PN}-peer.confd ${MY_PN}-peer
	keepdir /var/log/${MY_PN} /var/lib/${MY_PN}
	dodoc README.md
}
