# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Forked from ::gentoo openrgb-9999 (2026-08-06) because the tree's ebuild no
# longer builds against upstream master:
#  - OpenRGB-0.9-udev-check.patch stopped applying (the udev check moved from
#    ResourceManager.cpp to DetectionManager.cpp) and is obsolete anyway on
#    merged-usr profiles: the code now probes /usr/lib/udev/rules.d, exactly
#    where udev_dorules lands via the /lib -> usr/lib merge.
#  - Adds the Gainward RTX 5070 Ti Phoenix I2C detector (sub-device 0xF323),
#    not yet upstream — this host's GPU.

EAPI=8

inherit check-reqs flag-o-matic qmake-utils udev xdg-utils

inherit git-r3
EGIT_REPO_URI=${EGIT_REPO_URI:-"https://gitlab.com/CalcProgrammer1/OpenRGB"}

DESCRIPTION="Open source RGB lighting control"
HOMEPAGE="https://openrgb.org https://gitlab.com/CalcProgrammer1/OpenRGB/"
LICENSE="GPL-2"
# subslot is OPENRGB_PLUGIN_API_VERSION from
# https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/OpenRGBPluginInterface.h
SLOT="0/4"

RDEPEND="
	dev-cpp/cpp-httplib:=
	dev-libs/hidapi
	dev-qt/qtbase:6[gui,widgets]
	net-libs/mbedtls:0=
	virtual/libusb:1
"
DEPEND="
	${RDEPEND}
	dev-cpp/nlohmann_json
	dev-libs/mdns
	dev-libs/stb
"
BDEPEND="
	dev-qt/qttools:6[linguist]
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/OpenRGB-0.7-r1-udev.patch
	"${FILESDIR}"/openrgb-9999-gainward-rtx5070ti-phoenix.patch
)

CHECKREQS_DISK_BUILD="2G"

src_prepare() {
	default

	rm -r dependencies/{httplib,hidapi,libusb,mdns,json,mbedtls,stb}* \
		|| die "Failed to remove unneded deps"
}

src_configure() {
	# Some plugins require symbols defined in the main binary.
	# The upstream build system of plugins bundles OpenRGB as a submodule
	# instead, and compiles the .cpp file again.
	append-ldflags -Wl,--export-dynamic

	# > warning: '-pipe' ignored because '-save-temps' specified
	filter-flags -pipe

	# cpp-httplib >=0.16.0 changed the library name from "httplib" to "cpp-httplib".
	# See bug: https://bugs.gentoo.org/934576
	local -a libs=()
	if has_version "<dev-cpp/cpp-httplib-0.16.0" ; then
		libs+=( -lhttplib )
	else
		libs+=( -lcpp-httplib )
	fi

	eqmake6 \
		INCLUDEPATH+="${ESYSROOT}/usr/include/nlohmann" \
		INCLUDEPATH+="${ESYSROOT}/usr/include/stb" \
		OPENRGB_SYSTEM_PLUGIN_DIRECTORY="${EPREFIX}/usr/$(get_libdir)/openrgb/plugins" \
		LIBS+="${libs[@]}" \
		PREFIX="${EPREFIX}/usr"
}

src_install() {
	emake INSTALL_ROOT="${ED}" install

	dodoc README.md

	rm -r "${ED}"/usr/lib/udev/ || die
	udev_dorules 60-openrgb.rules

	# This is for plugins. Upstream doesn't install any headers at all.
	insinto /usr/include/OpenRGB
	find . -name '*.h' -exec cp --parents '{}' "${ED}/usr/include/OpenRGB/" ';' || die
}

pkg_postinst() {
	xdg_icon_cache_update
	udev_reload
}

pkg_postrm() {
	xdg_icon_cache_update
	udev_reload
}
