# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Optimized PyTree utilities (Keras dependency)"
HOMEPAGE="https://github.com/metaopt/optree https://pypi.org/project/optree/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
# Tests need pytest plugins not packaged here.
RESTRICT="test"

RDEPEND=">=dev-python/typing-extensions-4.12.0[${PYTHON_USEDEP}]"
# setup.py drives a CMake build of the pybind11 extension.
BDEPEND="
	dev-build/cmake
	>=dev-python/pybind11-2.12[${PYTHON_USEDEP}]
"
