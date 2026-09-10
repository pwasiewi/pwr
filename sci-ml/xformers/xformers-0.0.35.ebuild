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
# The FILESDIR patch keeps this a CPU-only build - no CUDA kernels are
# compiled. That is deliberate and sufficient: xformers.ops.SwiGLU dispatches
# to its eager PyTorch implementation when no fused kernel is present, which
# still runs on CUDA tensors, just unfused. Building the CUDA kernels against
# the live sci-ml/pytorch-9999 would be a long compile for no benefit here.

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
