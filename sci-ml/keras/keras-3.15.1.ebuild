# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Multi-backend deep learning API (JAX, TensorFlow, PyTorch)"
HOMEPAGE="https://keras.io https://github.com/keras-team/keras https://pypi.org/project/keras/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
# The test suite needs a backend and downloads datasets.
RESTRICT="test"

# TensorFlow >= 2.16 asks pip for keras-nightly; stable keras 3.x provides the same module.
RDEPEND="
	dev-python/absl-py[${PYTHON_USEDEP}]
	dev-python/h5py[${PYTHON_USEDEP}]
	dev-python/ml-dtypes[${PYTHON_USEDEP}]
	dev-python/namex[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/optree[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/rich[${PYTHON_USEDEP}]
"
