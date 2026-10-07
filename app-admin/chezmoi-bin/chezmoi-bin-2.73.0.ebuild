# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="Manage your dotfiles across multiple diverse machines, securely"
HOMEPAGE="https://www.chezmoi.io https://github.com/twpayne/chezmoi"
SRC_URI="
	amd64? (
		https://github.com/twpayne/chezmoi/releases/download/v${PV}/chezmoi_${PV}_linux_amd64.tar.gz
	)
	arm64? (
		https://github.com/twpayne/chezmoi/releases/download/v${PV}/chezmoi_${PV}_linux_arm64.tar.gz
	)
"
# tarball has no top-level directory
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# FOSS release asset, nothing to mirror; never strip a prebuilt Go binary
RESTRICT="mirror strip"

QA_PREBUILT="usr/bin/chezmoi"

src_install() {
	dobin chezmoi

	newbashcomp completions/chezmoi-completion.bash chezmoi
	dozshcomp completions/chezmoi.zsh
	dofishcomp completions/chezmoi.fish

	dodoc README.md
}
