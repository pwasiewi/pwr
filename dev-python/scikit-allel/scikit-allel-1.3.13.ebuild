# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Explore and analyse genetic variation data"
HOMEPAGE="
	https://github.com/cggh/scikit-allel
	https://pypi.org/project/scikit-allel/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# dask is NOT a hard dependency: allel/__init__.py guards `import dask` with
# try/except ImportError and only then exposes the dask-backed array classes.
# Upstream still declares dask[array] in project.dependencies.
RDEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/cython[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/setuptools-scm[${PYTHON_USEDEP}]
"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

python_test() {
	# The chunked-storage backends (zarr, h5py, numexpr) and dask are optional
	# extras; their test modules are skipped rather than pulled in.
	epytest allel -k "not zarr and not hdf5 and not dask"
}
