# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1 git-r3

DESCRIPTION="Fast LLM fine-tuning, reinforcement learning, and local training"
HOMEPAGE="https://github.com/unslothai/unsloth https://www.unsloth.ai"
EGIT_REPO_URI="https://github.com/unslothai/unsloth.git"
EGIT_BRANCH="main"

LICENSE="Apache-2.0 AGPL-3"
SLOT="0"

RDEPEND="
	sci-ml/unsloth-zoo[${PYTHON_SINGLE_USEDEP}]
	sci-ml/accelerate[${PYTHON_SINGLE_USEDEP}]
	sci-ml/datasets[${PYTHON_SINGLE_USEDEP}]
	sci-ml/huggingface_hub[${PYTHON_SINGLE_USEDEP}]
	sci-ml/peft[${PYTHON_SINGLE_USEDEP}]
	sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
	sci-ml/cut-cross-entropy[${PYTHON_SINGLE_USEDEP}]
	sci-ml/transformers[${PYTHON_SINGLE_USEDEP}]
	sci-ml/torchao[${PYTHON_SINGLE_USEDEP}]
	sci-ml/torchvision[${PYTHON_SINGLE_USEDEP}]
	sci-ml/trl[${PYTHON_SINGLE_USEDEP}]
	dev-python/bitsandbytes[${PYTHON_SINGLE_USEDEP}]
	dev-python/vllm[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/hf-transfer[${PYTHON_USEDEP}]
		dev-python/nest-asyncio[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/protobuf[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/pydantic[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/rich[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		dev-python/tyro[${PYTHON_USEDEP}]
		dev-python/typer[${PYTHON_USEDEP}]
		dev-python/wheel[${PYTHON_USEDEP}]
		sci-ml/safetensors[${PYTHON_USEDEP}]
		sci-ml/sentencepiece[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"
BDEPEND="
	$(python_gen_cond_dep '
		dev-python/setuptools-scm[${PYTHON_USEDEP}]
	')
"

# Upstream tests require network, GPUs, and heavyweight model downloads.
RESTRICT="test"

src_prepare() {
	default

	eapply "${FILESDIR}/${PN}-9999-disable-incompatible-vllm.patch"
}

pkg_postinst() {
	elog "Unsloth was installed from live git."
	elog "The pwr overlay now declares the GRPO-related Python deps."
	elog "sci-ml/torchao defaults to Python-only; enable USE=cpp to try its native extensions."
}
