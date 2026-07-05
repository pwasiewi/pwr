# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Upstream backend is scikit_build_core.setuptools.build_meta with
# wheel.cmake=false: the PEP517 build only packages a prebuilt
# libbitsandbytes*.so (via setuptools package-data).  We build the
# library with the cmake eclass and let the wheel pick it up from
# ${S}/bitsandbytes (LIBRARY_OUTPUT_DIRECTORY points there).
DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=standalone
PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_SINGLE_IMPL=1
CMAKE_BUILD_TYPE=Release

inherit cmake cuda distutils-r1

BNB_COMMIT="8ab26f751931610043f34938720d423bc80f5896"

DESCRIPTION="k-bit optimizers and matrix multiplication routines for PyTorch"
HOMEPAGE="
	https://github.com/bitsandbytes-foundation/bitsandbytes
	https://huggingface.co/docs/bitsandbytes/main
"
SRC_URI="https://github.com/bitsandbytes-foundation/bitsandbytes/archive/${BNB_COMMIT}.tar.gz -> ${P}.gh.tar.gz"
S="${WORKDIR}/${PN}-${BNB_COMMIT}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cpu +cuda rocm"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	?? ( cpu cuda rocm )
"

RDEPEND="
	${PYTHON_DEPS}
	~sci-ml/caffe2-9999[${PYTHON_SINGLE_USEDEP}]
	~sci-ml/pytorch-9999[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
		>=dev-python/packaging-20.9[${PYTHON_USEDEP}]
	')
	cuda? (
		dev-util/nvidia-cuda-toolkit:=
	)
	rocm? (
		>=dev-util/hip-7.2:=
		>=sci-libs/hipBLAS-7.2:=
		>=sci-libs/hipBLASLt-7.2:=
		>=sci-libs/hipRAND-7.2:=
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	$(python_gen_cond_dep '
		>=dev-python/scikit-build-core-0.11[${PYTHON_USEDEP}]
		>=dev-python/setuptools-77.0.3[${PYTHON_USEDEP}]
		>=dev-python/trove-classifiers-2025.8.6.13[${PYTHON_USEDEP}]
	')
	rocm? (
		>=dev-util/hip-7.2:=
		>=dev-util/hipcc-7.2:=
		>=sci-libs/hipBLAS-7.2:=
		>=sci-libs/hipBLASLt-7.2:=
		>=sci-libs/hipRAND-7.2:=
	)
"

RESTRICT="test"

bnb_compute_capability() {
	local archs=${CUDAARCHS:-}

	if [[ -z ${archs} && -n ${TORCH_CUDA_ARCH_LIST:-} ]]; then
		archs=${TORCH_CUDA_ARCH_LIST//+PTX/}
		archs=${archs//./}
	fi
	archs=${archs// /;}

	echo "${archs:-120}"
}

src_prepare() {
	sed -i \
		-e "s/^__version__ = .*/__version__ = \"${PV}\"/" \
		bitsandbytes/__init__.py || die

	cmake_src_prepare
	distutils-r1_src_prepare
}

src_configure() {
	local backend=cpu
	use cuda && backend=cuda
	use rocm && backend=hip

	local mycmakeargs=(
		-DCOMPUTE_BACKEND="${backend}"
	)

	if use cuda; then
		cuda_add_sandbox
		mycmakeargs+=(
			-DCOMPUTE_CAPABILITY="$(bnb_compute_capability)"
			-DCMAKE_CUDA_FLAGS="$(cuda_gccdir -f | tr -d \")"
		)
	fi

	if use rocm; then
		if [[ -n ${AMDGPU_TARGETS:-} ]]; then
			mycmakeargs+=( -DBNB_ROCM_ARCH="${AMDGPU_TARGETS}" )
		fi
	fi

	cmake_src_configure
	distutils-r1_src_configure
}

src_compile() {
	cmake_src_compile
	distutils-r1_src_compile
}

src_install() {
	distutils-r1_src_install
}
