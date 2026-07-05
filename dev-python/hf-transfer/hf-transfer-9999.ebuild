# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
DISTUTILS_USE_PEP517=maturin
DISTUTILS_EXT=1

inherit cargo distutils-r1 git-r3

DESCRIPTION="Fast file transfers for the Hugging Face Hub"
HOMEPAGE="https://github.com/huggingface/hf_transfer https://pypi.org/project/hf-transfer/"
EGIT_REPO_URI="https://github.com/huggingface/hf_transfer.git"
EGIT_BRANCH="main"

LICENSE="Apache-2.0"
SLOT="0"

DEPEND="
	dev-libs/openssl:=
"
RDEPEND="${DEPEND}"

# Tests require network access to remote Hugging Face endpoints.
RESTRICT="test"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_configure() {
	cargo_src_configure
	distutils-r1_src_configure
}
