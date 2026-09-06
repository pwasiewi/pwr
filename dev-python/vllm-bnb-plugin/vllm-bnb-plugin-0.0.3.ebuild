# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..14} )
PYPI_PN=vllm_bnb_plugin

inherit distutils-r1 pypi

DESCRIPTION="Out-of-tree bitsandbytes quantization plugin for vLLM"
HOMEPAGE="
	https://github.com/vllm-project/vllm-bnb-plugin
	https://pypi.org/project/vllm-bnb-plugin/
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

# vLLM 073c510c9 (2026-08-09, #43529) removed the in-tree
# vllm/model_executor/layers/quantization/bitsandbytes.py and
# model_loader/bitsandbytes_loader.py; every quantization="bitsandbytes" /
# load_format="bitsandbytes" user (unsloth's 4-bit fast_inference path among
# them) needs this plugin from that commit on. It registers itself through the
# vllm.general_plugins entry point, so installing is enough. 0.0.3 = tag
# v0.0.3 = upstream main d4914a9 (2026-08-24), tracks "new method name on
# vLLM main" (#10). sci-ml/unsloth-zoo carries a shim that aliases the old
# module paths to this package.
RDEPEND="
	dev-python/vllm[${PYTHON_SINGLE_USEDEP}]
	>=dev-python/bitsandbytes-0.48.1[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/packaging[${PYTHON_USEDEP}]
	')
"

# Tests need a GPU and a model download.
RESTRICT="test"
