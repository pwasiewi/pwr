# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit ecm

DESCRIPTION="Shader Wallpaper for Plasma 6 - native engine with PipeWire audio capture"
HOMEPAGE="https://github.com/y4my4my4m/kde-shader-wallpaper"
# PN follows upstream's CMake project name (plasma-wallpaper-shader); the
# git repository and therefore the tarball are named kde-shader-wallpaper.
SRC_URI="https://github.com/y4my4my4m/kde-shader-wallpaper/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.tar.gz"
S="${WORKDIR}/kde-shader-wallpaper-${PV}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+pipewire"

# CMakeLists asks for Qt >=6.6 but the generated cmake files pin Qt6Core
# >=6.9 (seen at configure time on 6.11).
# media-libs/shaderc is not optional here on purpose: without it (or glslang,
# which upstream only probes as a fallback) the engine silently drops to
# "precompiled shaders only" and every .frag in the gallery stops working.
DEPEND="
	>=dev-qt/qtbase-6.9:6[opengl]
	>=dev-qt/qtdeclarative-6.9:6[opengl]
	>=dev-qt/qtmultimedia-6.9:6
	kde-frameworks/kconfig:6
	kde-frameworks/ki18n:6
	kde-frameworks/kpackage:6
	kde-plasma/libplasma:6
	media-libs/shaderc
	pipewire? ( media-video/pipewire )
"
RDEPEND="${DEPEND}
	kde-plasma/plasma-workspace:6
"
BDEPEND="
	>=kde-frameworks/extra-cmake-modules-6.0.0:*
	virtual/pkgconfig
"

# The engine renders through QOpenGLShaderProgram/QOpenGLFramebufferObject:
# it needs the Qt Quick OpenGL RHI backend. With kdeglobals
# [QtQuickRendererSettings] SceneGraphBackend=vulkan (or the software one)
# the wallpaper is silently black.
pkg_postinst() {
	ewarn "This plugin requires plasmashell to run on the OpenGL scenegraph:"
	ewarn "  kwriteconfig6 --file kdeglobals --group QtQuickRendererSettings \\"
	ewarn "      --key SceneGraphBackend opengl"
	ewarn "A per-user copy in ~/.local/share/plasma/wallpapers shadows this"
	ewarn "system install - remove it to use the packaged version."
}
