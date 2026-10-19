# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 pypi

DESCRIPTION="Efficient Triton kernels for LLM training (fused RMSNorm, RoPE, SwiGLU, CE)"
HOMEPAGE="https://github.com/linkedin/Liger-Kernel https://pypi.org/project/liger-kernel/"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=sci-ml/pytorch-2.4[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		>=dev-python/triton-bin-3.0[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	$(python_gen_cond_dep '
		dev-python/setuptools-scm[${PYTHON_USEDEP}]
	')
"

# Tests require a CUDA GPU at runtime (Triton kernel launches).
RESTRICT="test"

pkg_postinst() {
	elog "Enable in HF Trainer scripts with e.g.:"
	elog "  from liger_kernel.transformers import apply_liger_kernel_to_gemma2"
	elog "or TrainingArguments(use_liger_kernel=True) on recent transformers."
}
