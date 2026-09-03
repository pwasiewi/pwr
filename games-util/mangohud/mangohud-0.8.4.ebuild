# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Based on ::guru games-util/mangohud-0.8.3 (2026). Differences: version bump
# to 0.8.4 (2026-05-27); imgui/implot are NOT unbundled — ::gentoo carries no
# media-libs/imgui or implot, so the meson wraps are satisfied from
# subprojects/packagecache with the exact archives upstream pins (hashes are
# verified by meson against the .wrap files). Both end up statically linked
# into the overlay library, which is what upstream ships anyway.

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit flag-o-matic python-single-r1 meson-multilib toolchain-funcs

DESCRIPTION="Vulkan and OpenGL overlay for monitoring FPS, sensors, system load and more"
HOMEPAGE="https://github.com/flightlessmango/MangoHud"

# Pinned in subprojects/*.wrap — the file names below must equal each wrap's
# source_filename / patch_filename, otherwise meson ignores the cache.
VK_VER="1.4.346"
IMGUI_VER="1.91.6"
IMPLOT_VER="0.16"
IMPLOT_WRAP_REV="1"

SRC_URI="
	https://github.com/flightlessmango/MangoHud/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/KhronosGroup/Vulkan-Headers/archive/v${VK_VER}.tar.gz
		-> vulkan-headers-${VK_VER}.tar.gz
	https://github.com/KhronosGroup/Vulkan-Utility-Libraries/archive/v${VK_VER}.tar.gz
		-> vulkan-utility-libraries-${VK_VER}.tar.gz
	https://github.com/ocornut/imgui/archive/refs/tags/v${IMGUI_VER}.tar.gz
		-> imgui-${IMGUI_VER}.tar.gz
	https://github.com/epezent/implot/archive/refs/tags/v${IMPLOT_VER}.zip
		-> implot-${IMPLOT_VER}.zip
	https://wrapdb.mesonbuild.com/v2/implot_${IMPLOT_VER}-${IMPLOT_WRAP_REV}/get_patch
		-> implot_${IMPLOT_VER}-${IMPLOT_WRAP_REV}_patch.zip
"
S="${WORKDIR}/MangoHud-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+dbus +X xnvctrl wayland mangoapp mangohudctl mangoplot video_cards_nvidia test"
RESTRICT="test" # tests aren't enabled upstream

REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	|| ( X wayland )
	xnvctrl? ( video_cards_nvidia X )
	mangoapp? ( X )
"

BDEPEND="
	app-arch/unzip
	dev-util/glslang
	test? ( dev-util/cmocka )
	$(python_gen_cond_dep 'dev-python/mako[${PYTHON_USEDEP}]')
"

DEPEND="
	${PYTHON_DEPS}
	dev-libs/spdlog:=[${MULTILIB_USEDEP}]
	dev-libs/libfmt:=[${MULTILIB_USEDEP}]
	x11-libs/libxkbcommon:=[${MULTILIB_USEDEP}]
	dbus? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	X? ( x11-libs/libX11[${MULTILIB_USEDEP}] )
	video_cards_nvidia? (
		x11-drivers/nvidia-drivers[${MULTILIB_USEDEP}]
		xnvctrl? ( x11-drivers/nvidia-drivers[static-libs] )
	)
	wayland? ( dev-libs/wayland[${MULTILIB_USEDEP}] )
	mangoapp? ( media-libs/glfw[X(+)?,wayland(+)?] )
"

RDEPEND="
	${DEPEND}
	media-libs/libglvnd[${MULTILIB_USEDEP}]
	media-libs/vulkan-loader[${MULTILIB_USEDEP}]
	mangoplot? (
		$(python_gen_cond_dep '
			|| (
				dev-python/matplotlib[gtk3,${PYTHON_USEDEP}]
				dev-python/matplotlib[qt5(-),${PYTHON_USEDEP}]
				dev-python/matplotlib[qt6(-),${PYTHON_USEDEP}]
				dev-python/matplotlib[wxwidgets,${PYTHON_USEDEP}]
			)
		')
	)
"

src_unpack() {
	unpack "${P}.tar.gz"
}

src_prepare() {
	default

	# Feed the wraps from the cache; meson checks source_hash/patch_hash.
	mkdir -p subprojects/packagecache || die
	local f
	for f in vulkan-headers-${VK_VER}.tar.gz \
		vulkan-utility-libraries-${VK_VER}.tar.gz \
		imgui-${IMGUI_VER}.tar.gz \
		implot-${IMPLOT_VER}.zip \
		implot_${IMPLOT_VER}-${IMPLOT_WRAP_REV}_patch.zip; do
		cp "${DISTDIR}/${f}" subprojects/packagecache/ || die
	done
}

multilib_src_configure() {
	# workaround for lld
	# https://github.com/flightlessmango/MangoHud/issues/1240
	if tc-ld-is-lld; then
		append-ldflags -Wl,--undefined-version
	fi

	local emesonargs=(
		-Dappend_libdir_mangohud=false
		-Dinclude_doc=false
		-Duse_system_spdlog=enabled
		$(meson_feature video_cards_nvidia with_nvml)
		$(meson_feature xnvctrl with_xnvctrl)
		$(meson_feature X with_x11)
		$(meson_feature wayland with_wayland)
		$(meson_feature dbus with_dbus)
		$(meson_use mangoapp mangoapp)
		$(meson_use mangohudctl mangohudctl)
		$(meson_feature mangoplot mangoplot)
		$(meson_feature test tests)
	)
	meson_src_configure
}

pkg_postinst() {
	elog "Steam launch options: mangohud %command%   (or MANGOHUD=1 for Vulkan only)"
	elog "Config: ~/.config/MangoHud/MangoHud.conf, env MANGOHUD_CONFIG=fps,frametime,…"
	elog "  steamctl opts add <game> mangohud   writes it for you."
	if ! use xnvctrl; then
		elog "Older NVIDIA GPUs that report no load: enable USE=xnvctrl."
	fi
}
