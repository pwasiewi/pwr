# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1

DESCRIPTION="State-of-the-art Parameter-Efficient Fine-Tuning (PEFT) methods"
HOMEPAGE="https://github.com/huggingface/peft"
SRC_URI="https://github.com/huggingface/${PN}/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.gh.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	sci-ml/accelerate[${PYTHON_SINGLE_USEDEP}]
	sci-ml/huggingface_hub[${PYTHON_SINGLE_USEDEP}]
	sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
	sci-ml/transformers[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		sci-ml/safetensors[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"

# Tests require network access (HuggingFace Hub model downloads) and
# unpackaged deps (diffusers), so no distutils_enable_tests.
