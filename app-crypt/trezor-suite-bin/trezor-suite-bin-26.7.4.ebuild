# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_BIN="Trezor-Suite-${PV}-linux-x86_64.AppImage"

DESCRIPTION="Official desktop application for Trezor hardware wallets (prebuilt)"
HOMEPAGE="https://trezor.io/trezor-suite https://github.com/trezor/trezor-suite"
SRC_URI="https://github.com/trezor/trezor-suite/releases/download/v${PV}/${MY_BIN}"
S="${WORKDIR}/squashfs-root"

LICENSE="T-RSL"
SLOT="0"
KEYWORDS="-* ~amd64"
# T-RSL forbids redistribution; strip would corrupt the Electron binaries.
RESTRICT="bindist mirror strip test"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/trezor-udev-rules
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
"

QA_PREBUILT="*"

src_unpack() {
	# Type-2 AppImage: the embedded static runtime extracts its own
	# squashfs payload; no fuse needed.
	cp "${DISTDIR}/${MY_BIN}" "${WORKDIR}/" || die
	chmod +x "${WORKDIR}/${MY_BIN}" || die
	cd "${WORKDIR}" || die
	"./${MY_BIN}" --appimage-extract >/dev/null || die "AppImage extraction failed"
	rm "${WORKDIR}/${MY_BIN}" || die
}

src_install() {
	local dest=/opt/trezor-suite

	insinto "${dest}"
	doins -r ./*
	rm "${ED}${dest}"/AppRun "${ED}${dest}"/trezor-suite.desktop || die

	fperms 0755 "${dest}"/trezor-suite "${dest}"/chrome_crashpad_handler
	# Electron SUID sandbox helper; without the bit the app only runs
	# with --no-sandbox or unprivileged user namespaces.
	fperms 4711 "${dest}"/chrome-sandbox

	dosym -r "${dest}"/trezor-suite /usr/bin/trezor-suite

	sed -e 's/^Exec=.*/Exec=trezor-suite %U/' trezor-suite.desktop \
		> "${T}"/trezor-suite.desktop || die
	domenu "${T}"/trezor-suite.desktop
	newicon -s 512 trezor-suite.png trezor-suite.png
}
