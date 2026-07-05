# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 git-r3

DESCRIPTION="PyTorch native quantization and sparsity tools"
HOMEPAGE="https://github.com/pytorch/ao https://pypi.org/project/torchao/"
EGIT_REPO_URI="https://github.com/pytorch/ao.git"
EGIT_BRANCH="main"

LICENSE="BSD"
SLOT="0"
IUSE="cpp"

RDEPEND="
	sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
"
DEPEND="${RDEPEND}"

# Upstream tests are GPU/model heavy. cpp enables local C++/CUDA extensions,
# but the default Python-only build is enough for imports and Unsloth wiring.
RESTRICT="test"

src_prepare() {
	default

	rm -rf test || die
}

python_compile() {
	export USE_CPP=$(usex cpp 1 0)
	export USE_CPU_KERNELS=0
	export BUILD_TORCHAO_EXPERIMENTAL=0

	distutils-r1_python_compile
}
