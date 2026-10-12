# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Upstream release binaries. Each archive holds one PIE, dynamically linked
# `camilladsp` built for a fixed backend set: plain = ALSA, pipewire = ALSA +
# native PipeWire, pulseaudio = ALSA + PulseAudio. All include the websocket
# server. USE picks the archive, pipewire taking precedence over pulseaudio
# (the desktop profiles set pulseaudio globally); see media-sound/camilladsp
# for a source build with tunable features.

EAPI=8

inherit systemd

MY_PN=${PN%-bin}
GITHUB_BASE="https://github.com/HEnquist/${MY_PN}/releases/download/v${PV}"

DESCRIPTION="Flexible audio DSP: convolution, biquads, mixers, loudness (upstream binaries)"
HOMEPAGE="https://github.com/HEnquist/camilladsp"
SRC_URI="
	amd64? (
		pipewire? ( ${GITHUB_BASE}/${MY_PN}-linux-pipewire-amd64.tar.gz -> ${P}-pipewire-amd64.tar.gz )
		!pipewire? (
			pulseaudio? ( ${GITHUB_BASE}/${MY_PN}-linux-pulseaudio-amd64.tar.gz -> ${P}-pulseaudio-amd64.tar.gz )
			!pulseaudio? ( ${GITHUB_BASE}/${MY_PN}-linux-amd64.tar.gz -> ${P}-alsa-amd64.tar.gz )
		)
	)
	arm64? (
		pipewire? ( ${GITHUB_BASE}/${MY_PN}-linux-pipewire-aarch64.tar.gz -> ${P}-pipewire-aarch64.tar.gz )
		!pipewire? (
			pulseaudio? ( ${GITHUB_BASE}/${MY_PN}-linux-pulseaudio-aarch64.tar.gz -> ${P}-pulseaudio-aarch64.tar.gz )
			!pulseaudio? ( ${GITHUB_BASE}/${MY_PN}-linux-aarch64.tar.gz -> ${P}-alsa-aarch64.tar.gz )
		)
	)
"
S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="+pipewire pulseaudio"
RESTRICT="mirror"

RDEPEND="
	media-libs/alsa-lib
	pipewire? ( media-video/pipewire )
	!pipewire? ( pulseaudio? ( media-libs/libpulse ) )
"

QA_PREBUILT="usr/bin/${MY_PN}"

src_install() {
	newbin "${MY_PN}" "${MY_PN}"
	systemd_douserunit "${FILESDIR}/${MY_PN}.service"
	printf 'CamillaDSP %s upstream build, backend: %s\n' "${PV}" \
		"$(usex pipewire pipewire "$(usex pulseaudio pulseaudio alsa)")" > "${T}/BACKEND" || die
	dodoc "${T}/BACKEND"
}

pkg_postinst() {
	elog "Per-user configs live in ~/.config/camilladsp/ (active.yml -> <name>.yml)."
	elog "Start with 'systemctl --user start camilladsp' or the dspctl switch script;"
	elog "the unit is not enabled by default so it never runs next to EasyEffects."
	use pipewire && elog "PipeWire backend: nodes camilladsp-capture / camilladsp-playback do not auto-connect; see backend_pipewire.md upstream."
}
