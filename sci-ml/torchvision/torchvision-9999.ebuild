# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
ROCM_SKIP_GLOBALS=1
inherit cuda distutils-r1 flag-o-matic git-r3 multiprocessing rocm

DESCRIPTION="Datasets, transforms and models to specific to computer vision (live)"
HOMEPAGE="https://github.com/pytorch/vision"
EGIT_REPO_URI="https://github.com/pytorch/vision.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/vision"
S="${WORKDIR}/vision"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"
IUSE="cuda +ffmpeg +jpeg +png rocm +webp"

REQUIRED_USE="
	?? ( cuda rocm )
"

# Own C++ extension linking the installed libtorch -> ABI lock-step with the
# HEAD frontend: pin ~pytorch-9999 (which pins caffe2-9999).  caffe2 dep left
# unpinned but transitively forced to 9999 through pytorch-9999.
RDEPEND="
	$(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
	')
	jpeg? ( media-libs/libjpeg-turbo:= )
	png? ( media-libs/libpng:= )
	webp? ( media-libs/libwebp )
	ffmpeg? ( media-video/ffmpeg )
	sci-ml/caffe2[cuda?,rocm?,${PYTHON_SINGLE_USEDEP}]
	~sci-ml/pytorch-9999[${PYTHON_SINGLE_USEDEP}]
"

# Tests pull network datasets; not wired up for the live ebuild.
RESTRICT="test"

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	use cuda && cuda_src_prepare
	distutils-r1_src_prepare
}

src_configure() {
	rocm_add_sandbox -w
	distutils-r1_src_configure
}

python_compile() {
	addpredict /dev/kfd
	# bug #968112
	addpredict /dev/random

	# torch.cpp_extension feeds CXXFLAGS verbatim to nvcc, which forwards them
	# to host gcc as COMPILE flags. Linker flags that leaked into CXXFLAGS
	# (-Wl,-O1 -Wl,--as-needed -Wl,-z,pack-relative-relocs) then abort the CUDA
	# kernel build with `gcc: unrecognized command-line option '-Wl'`. Strip
	# them here (cmake-based caffe2 is immune; this ninja/nvcc path is not).
	filter-flags '-Wl,*'

	export FORCE_CUDA=0
	if use cuda || use rocm ; then
	  export FORCE_CUDA=1
	fi

	export TORCHVISION_USE_PNG=$(usex png 1 0)
	export TORCHVISION_USE_JPEG=$(usex jpeg 1 0)
	export TORCHVISION_USE_WEBP=$(usex webp 1 0)
	export TORCHVISION_USE_FFMPEG=$(usex ffmpeg 1 0)

	export TORCHVISION_USE_NVJPEG=$(usex cuda 1 0)
	export TORCHVISION_USE_VIDEO_CODEC=$(usex cuda 1 0)

	NVCC_FLAGS="${NVCCFLAGS}" \
		MAX_JOBS="$(get_makeopts_jobs)" \
		distutils-r1_python_compile -j1
}
