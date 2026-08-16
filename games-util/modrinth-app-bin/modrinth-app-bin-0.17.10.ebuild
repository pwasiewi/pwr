# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

# Upstream monorepo is modrinth/code (formerly theseus); the desktop app
# releases carry the Modrinth.App_* asset names.
MY_PN="Modrinth.App"

DESCRIPTION="Modrinth App - mod manager and launcher for Minecraft (prebuilt)"
HOMEPAGE="https://modrinth.com/app https://github.com/modrinth/code"
SRC_URI="https://github.com/modrinth/code/releases/download/v${PV}/${MY_PN}_${PV}_amd64.deb"
S="${WORKDIR}"

# The app itself is GPL-3 (modrinth/code); it is a Tauri binary with
# statically vendored MIT/Apache Rust crates.
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip"

# Direct NEEDED sonames of usr/bin/ModrinthApp (objdump -p, 0.17.10):
# libwebkit2gtk-4.1 + libjavascriptcoregtk-4.1, libgtk-3/libgdk-3,
# libsoup-3.0, libglib/gio/gobject, libcairo, libgdk_pixbuf. The deb's own
# Depends agrees (libwebkit2gtk-4.1-0, libgtk-3-0). No appindicator — the
# binary neither links nor dlopens a tray library (strings-verified).
# Java is NOT a dependency: the launcher downloads and manages its own JRE
# per Minecraft version.
RDEPEND="
	dev-libs/glib:2
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
"

QA_PREBUILT="usr/bin/ModrinthApp"

src_install() {
	dobin usr/bin/ModrinthApp

	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	# upstream ships the desktop entry with a space in the filename;
	# keep it — StartupWMClass and the menu entry reference it as-is
	insinto /usr/share/applications
	doins usr/share/applications/"Modrinth App.desktop"
}
