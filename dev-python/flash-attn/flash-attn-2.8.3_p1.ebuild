# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Adapted from the stuff overlay (flash-attn-2.8.3_p1) for this host:
# python3_14 + Blackwell sm_120 SASS-only default (RTX 5070 Ti, CUDA 13.x).
# Needed by the HF (no-vLLM) generation/training paths in the GRPO stack —
# unsloth reports "FA2 = False" and falls back to sdpa without it.

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 pypi cuda

# csrc/cutlass is a git submodule that the PyPI sdist does NOT bundle (the
# 8.4MB sdist carries only flash-attn's own kernels). Supply it as a second
# distfile pinned to the exact submodule commit recorded in v${PV}'s tree
# (== CUTLASS 4.0.0) and stage it into csrc/cutlass before the build.
CUTLASS_COMMIT="dc4817921edda44a549197ff3a9dcf5df0636e7b"

DESCRIPTION="Fast and memory-efficient exact attention (FlashAttention-2)"
HOMEPAGE="
	https://github.com/Dao-AILab/flash-attention
	https://pypi.org/project/flash-attn/
"
SRC_URI+="
	https://github.com/NVIDIA/cutlass/archive/${CUTLASS_COMMIT}.tar.gz
		-> flash-attn-cutlass-${CUTLASS_COMMIT:0:8}.gh.tar.gz
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	sci-ml/caffe2[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/einops[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-alternatives/ninja
	$(python_gen_cond_dep '
		dev-python/setuptools[${PYTHON_USEDEP}]
	')
"

src_prepare() {
	# Stage the pinned CUTLASS into the submodule path setup.py expects;
	# without it the build aborts at the csrc/cutlass/include/cutlass.h check.
	rmdir csrc/cutlass 2>/dev/null
	mv "${WORKDIR}/cutlass-${CUTLASS_COMMIT}" csrc/cutlass || die

	# torch HEAD's ATen errors out below C++20; upstream setup.py pins -std=c++17
	# (same fix class as pwr's vllm-flash-attn cxx20 patch, 2026-07-19).
	sed -i 's/-std=c++17/-std=c++20/g' setup.py || die

	distutils-r1_src_prepare
}

src_compile() {
	local gccdir
	gccdir=$(cuda_gccdir) || die
	# torch's cpp_extension passes CC/CXX to nvcc as -ccbin; CUDA 13.x rejects
	# gcc>15, so pin the cuda-eclass gcc.
	export CC="${gccdir}/gcc" CXX="${gccdir}/g++"
	# Blackwell sm_120 SASS-only (torch cpp_extension wants the dotted form).
	# +PTX omitted on purpose: single-GPU host, smaller binaries.
	export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-12.0}"
	# setup.py IGNORES TORCH_CUDA_ARCH_LIST for its own -gencode list and
	# defaults to 80;90;100;120 (4x the compile time). Its knob is this one:
	export FLASH_ATTN_CUDA_ARCHS="${FLASH_ATTN_CUDA_ARCHS:-120}"
	export FORCE_CUDA=1 FLASH_ATTENTION_FORCE_BUILD=TRUE
	# The flash_bwd_hdim128 kernels peak ~10-13GB each under cicc; at the
	# upstream default MAX_JOBS they OOM the host. Cap parallelism (2x2
	# stays under ~26GB peak; raise via env only with a quiet desktop).
	export MAX_JOBS="${MAX_JOBS:-2}" NVCC_THREADS="${NVCC_THREADS:-2}"

	distutils-r1_src_compile
}
