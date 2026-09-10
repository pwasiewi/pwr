# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

# Imported into ::pwr from ::stuff 2026-09-10. Reason it is needed at all:
# chandar-lab/NeoBERT's remote code does `from xformers.ops import SwiGLU` at
# module scope, with no try/except, so the model cannot even be imported
# without this package (its flash_attn import IS guarded and falls back to
# SDPA, but the SwiGLU one is not). Used by llm/lc_11_neobert_imdb.py.
#
# No CUDA kernels are compiled here (the FILESDIR patch plus the phase
# overrides below - see the long note further down, the patch alone does NOT
# achieve this). That is deliberate and sufficient: xformers.ops.SwiGLU
# dispatches to its eager PyTorch implementation when no fused kernel is
# present, which still runs on CUDA tensors, just unfused. Building the CUDA
# kernels against the live sci-ml/pytorch-9999 would be a long compile for no
# benefit here.

DESCRIPTION="Composable building blocks for transformer models"
HOMEPAGE="
	https://github.com/facebookresearch/xformers
	https://pypi.org/project/xformers/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

PATCHES=( "${FILESDIR}/${P}-disable-accelerator-probe.patch" )

# The test suite primarily exercises accelerator kernels.
RESTRICT="test"

RDEPEND="
	sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep 'dev-python/numpy[${PYTHON_USEDEP}]')
"
BDEPEND="
	${RDEPEND}
	dev-build/ninja
"

# Build the portable CPU extension without probing accelerator device nodes.
export CUDA_VISIBLE_DEVICES=""
export HIP_VISIBLE_DEVICES=""
export ROCR_VISIBLE_DEVICES=""
export XFORMERS_DISABLE_ACCELERATOR=1

# XFORMERS_DISABLE_ACCELERATOR ALONE IS NOT ENOUGH, and this is the ::stuff
# ebuild's bug. The FILESDIR patch only guards the first disjunct of setup.py's
# accelerator test; the condition is a three-way or:
#
#   if ( <patched: DISABLE!=1 and torch.cuda.is_available() and ...>
#        or os.getenv("FORCE_CUDA", "0") == "1"
#        or os.getenv("TORCH_CUDA_ARCH_LIST", "") != "" ):
#
# so anything that exports TORCH_CUDA_ARCH_LIST re-enables the CUDA extension
# behind the flag's back. That is not hypothetical here: this host sets
# TORCH_CUDA_ARCH_LIST="12.0" globally in make.conf for the sci-ml/pytorch and
# sci-ml/caffe2 builds, and it leaks into every other package. The result was a
# full nvcc build of the sparse24/gemm kernels that then died on
#   host_config.h:137: #error -- unsupported GNU version! gcc versions later
#   than 15 are not supported!
# because this host is gcc 16.2.0 against CUDA 13.3.
#
# Neutralise both bypasses so the disable flag means what it says. Empty (not
# unset) is what setup.py tests for.
#
# Scoped to the phase with `local -x` rather than exported at global scope:
# TORCH_CUDA_ARCH_LIST is a make.conf variable that other packages in this tree
# (sci-ml/pytorch, sci-ml/caffe2) legitimately need, so the override is kept as
# narrow as the problem - this one build, this one phase.

python_compile() {
	local -x TORCH_CUDA_ARCH_LIST=""
	local -x FORCE_CUDA=0
	distutils-r1_python_compile
}
