# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
inherit distutils-r1 flag-o-matic git-r3 multiprocessing

DESCRIPTION="Audio data, transforms and models for PyTorch (live)"
HOMEPAGE="https://github.com/pytorch/audio"
EGIT_REPO_URI="https://github.com/pytorch/audio.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/audio"
S="${WORKDIR}/audio"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

# torchaudio builds its own C++ extension linking the installed libtorch, so
# it inherits pytorch's ABI: a HEAD frontend must pair with pytorch-9999 (which
# itself pins caffe2-9999).  A stable pytorch tag would mismatch HEAD's ATen /
# TORCH_LIBRARY C++ API.  Exact ~9999 pin — no stable floor.
RDEPEND="
	~sci-ml/pytorch-9999[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
	')
"

# Tests pull soundfile + a network corpus; not wired up.
RESTRICT="test"

src_unpack() {
	git-r3_src_unpack
}

python_compile() {
	# CPU-only, mirroring the stable ebuild: the CUDA/ROCm code paths need the
	# setup_helpers env dance torchvision does.  The CPU extension still links
	# cleanly against a CUDA-enabled libtorch.
	export USE_CUDA=0
	export USE_ROCM=0
	export BUILD_CUDA_CTC_DECODER=0

	# Strip linker flags that leaked into CXXFLAGS so the C++ extension build
	# doesn't choke on -Wl,* (see torchvision-9999 for the nvcc variant).
	filter-flags '-Wl,*'

	MAX_JOBS="$(get_makeopts_jobs)" \
		distutils-r1_python_compile -j1
}
