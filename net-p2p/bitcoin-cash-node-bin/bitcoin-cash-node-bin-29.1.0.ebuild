# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

MY_P="bitcoin-cash-node-${PV}"

DESCRIPTION="Bitcoin Cash Node (BCHN) full node — official prebuilt binaries"
HOMEPAGE="https://bitcoincashnode.org https://github.com/bitcoin-cash-node/bitcoin-cash-node"
SRC_URI="
	amd64? (
		https://github.com/bitcoin-cash-node/bitcoin-cash-node/releases/download/v${PV}/${MY_P}-x86_64-linux-gnu.tar.gz
	)
	arm64? (
		https://github.com/bitcoin-cash-node/bitcoin-cash-node/releases/download/v${PV}/${MY_P}-aarch64-linux-gnu.tar.gz
	)
"
S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# Upstream release binaries link only glibc/libgcc (deps built static).
RESTRICT="mirror strip"

RDEPEND="
	acct-group/bitcoin
	acct-user/bitcoin
"

QA_PREBUILT="usr/bin/*"

src_install() {
	# bitcoin-qt (drags a Qt runtime, this is a headless node package) and
	# bitcoin-seeder (DNS seeder, not node runtime) are deliberately skipped.
	dobin bin/bitcoind bin/bitcoin-cli bin/bitcoin-tx bin/bitcoin-wallet
	doman share/man/man1/bitcoind.1 share/man/man1/bitcoin-cli.1 \
		share/man/man1/bitcoin-tx.1

	keepdir /var/lib/bitcoind
	fowners bitcoin:bitcoin /var/lib/bitcoind
	fperms 0750 /var/lib/bitcoind

	# May carry RPC credentials once edited — group-readable only.
	insinto /etc/bitcoin
	newins "${FILESDIR}"/bitcoin.conf bitcoin.conf
	fowners root:bitcoin /etc/bitcoin/bitcoin.conf
	fperms 0640 /etc/bitcoin/bitcoin.conf

	systemd_dounit "${FILESDIR}"/bitcoind.service
}

pkg_postinst() {
	elog "Data directory: /var/lib/bitcoind (config: /etc/bitcoin/bitcoin.conf)."
	elog "Budget ~250 GB and growing for the BCH chain — SSD strongly advised."
	elog "Start: systemctl enable --now bitcoind"
	elog "CLI as the service user, e.g.:"
	elog "  sudo -u bitcoin bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf -datadir=/var/lib/bitcoind getblockchaininfo"
	elog "BCH hard-forks every May 15 12:00 UTC — upgrade this package FIRST."
}
