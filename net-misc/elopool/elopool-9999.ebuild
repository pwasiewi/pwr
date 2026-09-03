# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools systemd

DESCRIPTION="EloPool — ckpool fork with native CashAddr for BCH solo mining"
HOMEPAGE="https://github.com/skaisser/ckpool"
if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/skaisser/ckpool.git"
else
	SRC_URI="https://github.com/skaisser/ckpool/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/ckpool-${PV}"
	KEYWORDS="~amd64 ~arm64"
fi

LICENSE="GPL-3"
SLOT="0"

# zeromq is an automagic configure probe (AC_SEARCH_LIBS, no --with switch) —
# depend on it unconditionally so the feature set never depends on what the
# build host happens to have installed. jansson is vendored (static, 2.14).
DEPEND="net-libs/zeromq"
RDEPEND="
	${DEPEND}
	acct-group/bitcoin
	acct-user/bitcoin
"
# yasm assembles the SSE4/AVX sha256 paths; x86-only (arm64 uses the
# compiler-built sha256_arm_shani.c behind its own configure probe).
BDEPEND="amd64? ( dev-lang/yasm )"

src_prepare() {
	default
	# Upstream's install-exec-hook setcaps the LIVE $(bindir)/ckpool — no
	# DESTDIR, a sandbox violation; and stratum on :3333 needs no capability.
	sed -i '/setcap/d' src/Makefile.am || die "setcap hook removal failed"
	eautoreconf
}

src_install() {
	# installs ckpool, ckpmsg, notifier + the ckproxy symlink
	default

	# test/Makefile.am ships its unit-test drivers as bin_PROGRAMS with
	# collision-grade names — nothing runtime needs them
	rm "${ED}"/usr/bin/{sha256,cashaddr,addrclassify} || die

	insinto /etc/ckpool
	doins ckpool.conf
	# The pool config carries node RPC credentials once edited.
	fowners root:bitcoin /etc/ckpool/ckpool.conf
	fperms 0640 /etc/ckpool/ckpool.conf

	# Unit's WorkingDirectory — upstream's relative "logdir": "logs" lands
	# here; also the natural home for the users/ share database.
	keepdir /var/lib/ckpool
	fowners bitcoin:bitcoin /var/lib/ckpool
	fperms 0750 /var/lib/ckpool

	systemd_dounit "${FILESDIR}"/elopool.service

	dodoc README.md README-SOLOMINING POOL_FEE.md CKPOOL_API_GUIDE.md \
		ckproxy.conf cknode.conf ckpassthrough.conf ckredirector.conf
}

pkg_postinst() {
	elog "Edit /etc/ckpool/ckpool.conf: btcd url/auth to the local BCHN RPC,"
	elog "YOUR payout address as bchaddress, poolfee 0 for solo, serverurl"
	elog "0.0.0.0:3333. State/logs live in /var/lib/ckpool."
	elog "Start solo mode: systemctl enable --now elopool"
	elog "Difficulty pin for a Bitaxe rides the stratum password: -p d=N"
}
