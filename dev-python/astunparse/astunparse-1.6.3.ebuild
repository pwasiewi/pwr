# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="An AST unparser for Python (TensorFlow dependency)"
HOMEPAGE="https://github.com/simonpercivall/astunparse https://pypi.org/project/astunparse/"

LICENSE="BSD PSF-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/six-1.6.1[${PYTHON_USEDEP}]
	>=dev-python/wheel-0.23.0[${PYTHON_USEDEP}]
"
