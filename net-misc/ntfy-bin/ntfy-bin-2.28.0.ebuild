# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Simple HTTP-based pub-sub push notification service (server and client)"
HOMEPAGE="https://ntfy.sh https://github.com/binwiederhier/ntfy"
SRC_URI="
	amd64? (
		https://github.com/binwiederhier/ntfy/releases/download/v${PV}/ntfy_${PV}_linux_amd64.tar.gz
	)
	arm64? (
		https://github.com/binwiederhier/ntfy/releases/download/v${PV}/ntfy_${PV}_linux_arm64.tar.gz
	)
"
# arch-dependent top-level directory inside the tarball — resolved in src_install
S="${WORKDIR}"

# upstream dual-licenses: "Apache License 2.0 or GPLv2"
LICENSE="|| ( Apache-2.0 GPL-2 )"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# FOSS binary: mirroring is fine upstream-side but pointless for a release
# asset; never strip a prebuilt static Go binary
RESTRICT="mirror strip"

QA_PREBUILT="usr/bin/ntfy"

RDEPEND="
	acct-group/ntfy
	acct-user/ntfy
"

src_install() {
	local d="ntfy_${PV}_linux_$(usex amd64 amd64 arm64)"
	dobin "${d}/ntfy"

	# upstream annotated examples; CONFIG_PROTECT keeps a live config intact
	insinto /etc/ntfy
	doins "${d}/server/server.yml" "${d}/client/client.yml"

	# own unit, not upstream's: /usr/bin path, sandbox directives upstream
	# still marks "future", no CAP_NET_BIND_SERVICE (default port is 80 in
	# their unit; a server.yml here is expected to pick an unprivileged one)
	systemd_dounit "${FILESDIR}/ntfy.service"

	keepdir /var/lib/ntfy /var/lib/ntfy/attachments
	fowners ntfy:ntfy /var/lib/ntfy /var/lib/ntfy/attachments
	fperms 750 /var/lib/ntfy /var/lib/ntfy/attachments

	dodoc "${d}/README.md"
}

pkg_postinst() {
	elog "Server config: /etc/ntfy/server.yml (set listen-http, base-url and"
	elog "cache-file there), client config: /etc/ntfy/client.yml."
	elog "Start with: systemctl enable --now ntfy"
	if [[ -x ${EROOT}/usr/local/bin/ntfy ]]; then
		ewarn "A hand-installed ${EROOT}/usr/local/bin/ntfy exists and shadows"
		ewarn "the packaged /usr/bin/ntfy in PATH — remove it. If a unit at"
		ewarn "/etc/systemd/system/ntfy.service points there, remove it too:"
		ewarn "the packaged unit lives in $(systemd_get_systemunitdir)."
	fi
}
