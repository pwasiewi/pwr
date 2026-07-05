# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=scikit-build-core
PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 git-r3

DESCRIPTION="k-bit optimizers and matrix multiplication routines for PyTorch (live)"
HOMEPAGE="
	https://github.com/bitsandbytes-foundation/bitsandbytes
	https://huggingface.co/docs/bitsandbytes/main
"
EGIT_REPO_URI="https://github.com/bitsandbytes-foundation/bitsandbytes.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/${PN}"
S="${WORKDIR}/${PN}"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"
IUSE="cpu +cuda rocm"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	^^ ( cpu cuda rocm )
"

RDEPEND="
	${PYTHON_DEPS}
	>=sci-ml/pytorch-2.4[${PYTHON_SINGLE_USEDEP}]
	<sci-ml/pytorch-3[${PYTHON_SINGLE_USEDEP}]
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
	>=dev-build/cmake-3.22.1
	app-alternatives/ninja
	$(python_gen_cond_dep '
		>=dev-python/scikit-build-core-0.11[${PYTHON_USEDEP}]
		>=dev-python/setuptools-77.0.3[${PYTHON_USEDEP}]
		>=dev-python/trove-classifiers-2025.8.6.13[${PYTHON_USEDEP}]
	')
	cuda? (
		dev-util/nvidia-cuda-toolkit:=
	)
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
		-e '/wheel\.cmake = false/d' \
		-e "s/__version__ = .*/__version__ = \"${PV}\"/" \
		bitsandbytes/__init__.py pyproject.toml || die

	distutils-r1_src_prepare
}

python_configure_all() {
	local backend=cpu
	use cuda && backend=cuda
	use rocm && backend=hip

	DISTUTILS_ARGS=(
		-DCMAKE_BUILD_TYPE=Release
		-DCOMPUTE_BACKEND="${backend}"
	)

	if use cuda; then
		DISTUTILS_ARGS+=(
			-DCOMPUTE_CAPABILITY="$(bnb_compute_capability)"
		)
		if [[ -n ${BNB_CUDA_VERSION:-} ]]; then
			DISTUTILS_ARGS+=( -DCUDA_VERSION="${BNB_CUDA_VERSION}" )
		fi
	fi

	if use rocm; then
		if [[ -n ${AMDGPU_TARGETS:-} ]]; then
			DISTUTILS_ARGS+=( -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" )
		fi
		if [[ -n ${BNB_ROCM_VERSION:-} ]]; then
			DISTUTILS_ARGS+=( -DROCM_VERSION="${BNB_ROCM_VERSION}" )
		fi
	fi
}

python_compile() {
	local v
	for v in CFLAGS CXXFLAGS CPPFLAGS; do
		export ${v}="$(sed 's/-Wl,[^ ]*//g' <<<"${!v}")"
	done

	distutils-r1_python_compile
}
