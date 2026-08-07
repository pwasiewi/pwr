# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop systemd xdg-utils

MY_PN="cisco-secure-client-linux64"
MY_P="${MY_PN}-${PV}-core-vpn-webdeploy-k9"

DESCRIPTION="Cisco Secure Client (formerly AnyConnect) SSL/IPsec VPN client"
HOMEPAGE="https://www.cisco.com/c/en/us/support/security/secure-client-5/model.html"
SRC_URI="${MY_P}.sh"
S="${WORKDIR}/vpn"

LICENSE="Cisco-EULA"
SLOT="0"
KEYWORDS="-* ~amd64"

IUSE="+gui +webkit"

# The installer is only downloadable from software.cisco.com behind a Cisco
# account with an entitled service contract, so Portage cannot fetch it and it
# must not be mirrored or redistributed. Everything shipped is a prebuilt,
# vendor-signed binary: stripping would invalidate the signature the agent
# checks against VPNManifest.dat, and there are no sources to build or test.
RESTRICT="bindist fetch mirror strip test"

# libvpn*.so and friends resolve through RUNPATH inside ${INSTPREFIX}/lib, so
# only the genuinely external sonames are listed here, read out of the NEEDED
# entries of the shipped binaries rather than guessed. The one that is easy to
# get wrong:
#
#   libxml2.so.2  -> dev-libs/libxml2-compat. ::gentoo's libxml2:2 is at
#                    .so.16 now, so the compat package is what actually
#                    provides the soname vpnagentd, vpn and vpnui want.
#
# gtk+:3 is unconditional because vpndownloader links it even without USE=gui.
RDEPEND="
	dev-libs/glib:2
	dev-libs/libxml2-compat:2
	sys-apps/systemd:=
	sys-libs/zlib:0
	x11-libs/gtk+:3
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/pango
	app-accessibility/at-spi2-core:2
	webkit? (
		net-libs/webkit-gtk:4
		net-libs/libsoup:2.4
	)
"

QA_PREBUILT="opt/cisco/secureclient/bin/* opt/cisco/secureclient/lib/*"

# Everything under /opt/cisco/secureclient is vendor-supplied; the two files
# generated at first install (AnyConnectLocalPolicy.xml and VPNManifest.dat)
# are runtime state, see pkg_postinst.
QA_FLAGS_IGNORED="opt/cisco/secureclient/.*"

pkg_nofetch() {
	einfo "Download ${MY_P}.sh from Cisco:"
	einfo
	einfo "  https://software.cisco.com/download/home/286330811/type"
	einfo
	einfo "A Cisco account with an entitled service contract is required —"
	einfo "the file is not publicly downloadable, which is why RESTRICT=fetch"
	einfo "is set. Place it in ${DISTDIR}."
	einfo
	einfo "This host stages restricted distfiles in"
	einfo "  ~/Claude/rpilinuxlab/dl/distfiles-restricted/"
	einfo "and 'xp <profile> restrict-run' copies them into the build DISTDIR."
}

src_unpack() {
	# The .sh is a shell header followed by a base-64-free gzip payload
	# delimited by two line markers. Reproduce the vendor's own extraction
	# (vpn_install.sh does head -n END | tail -n +BEGIN | head -c -1) rather
	# than executing the installer: it wants to run systemctl, write outside
	# ${D} and enable a service, none of which belongs in src_*.
	local src="${DISTDIR}/${A}"
	local begin end

	begin=$(( $(grep -an '[B]EGIN ARCHIVE' "${src}" | cut -d: -f1) + 1 ))
	end=$(( $(grep -an '[E]ND ARCHIVE' "${src}" | cut -d: -f1) - 1 ))
	[[ ${begin} -gt 1 && ${end} -gt ${begin} ]] ||
		die "archive markers not found in ${A} — installer format changed"

	# head -c -1 drops the newline the marker line contributes.
	head -n "${end}" "${src}" | tail -n +"${begin}" | head -c -1 \
		> "${WORKDIR}"/payload.tar.gz || die "extracting payload failed"

	unpack ./payload.tar.gz
}

src_install() {
	local instprefix="/opt/cisco/secureclient"

	# --- libraries -----------------------------------------------------
	exeinto "${instprefix}"/lib
	doexe cfom.so libacciscocrypto.so libacciscossl.so libacruntime.so \
		libaccurl.so.4.8.0 libvpnagentutilities.so libvpnapi.so \
		libvpncommon.so libvpncommoncrypt.so \
		libboost_atomic.so libboost_chrono.so libboost_date_time.so \
		libboost_filesystem.so libboost_regex.so libboost_system.so \
		libboost_thread.so
	dosym libaccurl.so.4.8.0 "${instprefix}"/lib/libaccurl.so.4

	# --- plugins -------------------------------------------------------
	exeinto "${instprefix}"/bin/plugins
	doexe libacdownloader.so libacfeedback.so libacwebhelper.so libvpnipsec.so

	# --- executables ---------------------------------------------------
	exeinto "${instprefix}"/bin
	doexe acinstallhelper acextwebhelper manifesttool_vpn \
		vpn vpnagentd vpndownloader vpndownloader-cli \
		load_tun.sh vpn_uninstall.sh cisco_secure_client_uninstall.sh

	# acwebhelper is the whole reason webkit-gtk:4 appears here — it is the
	# only binary in the payload that links libwebkit2gtk-4.0.so.37. vpnui
	# does not; it is plain GTK3. libacwebhelper.so above stays unconditional
	# because it dispatches to either helper depending on the headend's
	# IsExternalBrowser setting, and acextwebhelper needs no webkit at all.
	use webkit && doexe acwebhelper
	use gui && doexe vpnui

	# Legacy name some Cisco tooling still calls.
	dosym manifesttool_vpn "${instprefix}"/bin/manifesttool

	# --- data ----------------------------------------------------------
	insinto "${instprefix}"
	doins ACManifestVPN.xml AnyConnectLocalPolicy.xsd OpenSource.html update.txt

	insinto "${instprefix}"/vpn/profile
	doins AnyConnectProfile.xsd

	# Drop zones the installer creates empty: the headend pushes scripts,
	# help content and extra localizations into these at connect time.
	keepdir "${instprefix}"/vpn/script
	keepdir "${instprefix}"/help
	keepdir "${instprefix}"/l10n

	insinto "${instprefix}"
	doins -r resources

	# Root CAs the agent trusts for server certificates, kept in the
	# vendor's own store rather than the system one.
	insinto /opt/.cisco/certificates/ca
	doins DigiCertAssuredIDRootCA.pem \
		VeriSignClass3PublicPrimaryCertificationAuthority-G5.pem

	# Legacy path: older Cisco packages and some server-pushed downloaders
	# look for the manifest under /opt/cisco/anyconnect.
	dodir /opt/cisco/anyconnect
	dosym ../secureclient/ACManifestVPN.xml /opt/cisco/anyconnect/ACManifestVPN.xml

	# --- service -------------------------------------------------------
	# The vendor unit drops into /etc/systemd/system, which is admin
	# territory; a package belongs in the unit dir. EnvironmentFile also
	# gets a '-' prefix: without it systemd refuses to start the agent on a
	# host that has no /etc/environment.
	sed -e 's:^EnvironmentFile=/etc/environment:EnvironmentFile=-/etc/environment:' \
		vpnagentd.service > "${T}"/vpnagentd.service || die
	systemd_dounit "${T}"/vpnagentd.service

	# --- desktop -------------------------------------------------------
	if use gui; then
		domenu com.cisco.secureclient.gui.desktop

		insinto /usr/share/desktop-directories
		doins cisco-secure-client.directory

		insinto /etc/xdg/menus/applications-merged
		doins cisco-secure-client.menu

		local size
		for size in 48 64 96 128 256 512; do
			newicon -s ${size} resources/vpnui${size}.png \
				cisco-secure-client.png
		done
	fi

	dodoc license.txt
}

pkg_postinst() {
	use gui && xdg_desktop_database_update
	use gui && xdg_icon_cache_update

	local instprefix="${EROOT}/opt/cisco/secureclient"

	# Two files the vendor generates at install time rather than shipping.
	# They are host state, not package content, so they are made here and
	# deliberately left unowned — the same way ca-certificates builds its
	# bundle.
	if [[ ! -f ${instprefix}/AnyConnectLocalPolicy.xml ]]; then
		einfo "Generating AnyConnectLocalPolicy.xml"
		"${instprefix}"/bin/acinstallhelper -acpolgen \
			bd=false rswd=false rhwd=false rrwd=false rlwd=false \
			fm=false rpc=false rtp=false rwl=false sct=false efn=false \
			upsu=true upcu=true upvp=true upmv=true upip=true upsp=true \
			upscr=true uphlp=true upres=true uploc=true \
			rsc=false orc=false ||
			ewarn "acinstallhelper failed; the agent will use built-in defaults"
	fi

	einfo "Refreshing VPNManifest.dat"
	"${instprefix}"/bin/manifesttool_vpn -i "${instprefix}" \
		"${instprefix}"/ACManifestVPN.xml ||
		ewarn "manifesttool_vpn failed; server-pushed upgrades may misbehave"

	elog
	elog "Start the agent before connecting:"
	elog "  systemctl enable --now vpnagentd.service"
	elog
	elog "Then connect with either:"
	elog "  /opt/cisco/secureclient/bin/vpn connect <host>   (CLI)"
	use gui && elog "  /opt/cisco/secureclient/bin/vpnui                 (GUI)"
	elog
	if ! use webkit; then
		elog "Built with USE=-webkit: the embedded SAML/SSO browser is not"
		elog "installed. Headends that use SAML will fall back to opening"
		elog "your normal desktop browser via acextwebhelper. If a headend"
		elog "insists on the embedded browser, rebuild with USE=webkit."
		elog
	fi
	elog "The agent needs the tun module; load_tun.sh in ExecStartPre handles"
	elog "that, but a kernel with CONFIG_TUN=y needs no action."
}

pkg_postrm() {
	use gui && xdg_desktop_database_update
	use gui && xdg_icon_cache_update
}
