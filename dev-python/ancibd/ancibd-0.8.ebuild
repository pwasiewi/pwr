# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Identify IBD segments in ancient DNA from imputed diploid genotypes"
HOMEPAGE="
	https://github.com/hringbauer/ancIBD
	https://pypi.org/project/ancIBD/
"
SRC_URI="$(pypi_sdist_url ancIBD)"
S="${WORKDIR}/ancibd-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

# RDEPEND is derived from the imports in the installed tree, not from
# project.dependencies: upstream also declares pysam and psutil, which no module
# imports (0 hits across every .py in the sdist).
RDEPEND="
	dev-python/h5py[${PYTHON_USEDEP}]
	dev-python/matplotlib[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pandas[${PYTHON_USEDEP}]
	dev-python/scikit-allel[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/cython[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
"

# The sdist carries no tests and no docs/ directory, only example notebooks.
RESTRICT="test"
