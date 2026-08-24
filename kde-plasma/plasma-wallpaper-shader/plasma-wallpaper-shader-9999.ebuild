# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit ecm git-r3

DESCRIPTION="Shader Wallpaper for Plasma 6 - native engine with PipeWire audio capture"
HOMEPAGE="https://github.com/y4my4my4m/kde-shader-wallpaper"
# Tracks upstream master. This used to build from the pwasiewi fork because
# upstream lacked the raw-GL audio texture and the buffer-FBO state reset;
# both landed with the Ember/Ring_Spectrum/Hive_Spectrum shaders in PR #125
# (released as v4.1.1), so the fork carries nothing extra any more.
# To build a fork branch without editing this ebuild, git-r3 takes overrides
# keyed on the repository name, not on ${PN}:
#   EGIT_OVERRIDE_REPO_KDE_SHADER_WALLPAPER=https://github.com/pwasiewi/kde-shader-wallpaper.git
#   EGIT_OVERRIDE_BRANCH_KDE_SHADER_WALLPAPER=<branch>
EGIT_REPO_URI="https://github.com/y4my4my4m/kde-shader-wallpaper.git"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="+pipewire"

# CMakeLists asks for Qt >=6.6 but the generated cmake files pin Qt6Core
# >=6.9 (seen at configure time on 6.11).
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
