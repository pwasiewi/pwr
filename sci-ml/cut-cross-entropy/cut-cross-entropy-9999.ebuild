# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 git-r3

DESCRIPTION="Memory efficient linear cross entropy loss for PyTorch"
HOMEPAGE="https://github.com/apple/ml-cross-entropy https://pypi.org/project/cut-cross-entropy/"
EGIT_REPO_URI="https://github.com/apple/ml-cross-entropy.git"
EGIT_BRANCH="main"

LICENSE="Apple-Sample-Code"
SLOT="0"

RDEPEND="
	>=sci-ml/pytorch-2.4[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		>=dev-python/triton-bin-3.0[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"
BDEPEND="
	$(python_gen_cond_dep '
		dev-python/setuptools-scm[${PYTHON_USEDEP}]
	')
"

# Tests require CUDA/Triton runtime kernels and are too heavy for default QA.
RESTRICT="test"
