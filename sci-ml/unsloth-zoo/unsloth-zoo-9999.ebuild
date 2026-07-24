# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1 git-r3

DESCRIPTION="Utilities shared by Unsloth"
HOMEPAGE="https://github.com/unslothai/unsloth-zoo https://www.unsloth.ai"
EGIT_REPO_URI="https://github.com/unslothai/unsloth-zoo.git"
EGIT_BRANCH="main"

LICENSE="LGPL-3"
SLOT="0"

RDEPEND="
	~sci-ml/pytorch-9999[${PYTHON_SINGLE_USEDEP}]
	sci-ml/accelerate[${PYTHON_SINGLE_USEDEP}]
	sci-ml/datasets[${PYTHON_SINGLE_USEDEP}]
	sci-ml/huggingface_hub[${PYTHON_SINGLE_USEDEP}]
	sci-ml/peft[${PYTHON_SINGLE_USEDEP}]
	sci-ml/cut-cross-entropy[${PYTHON_SINGLE_USEDEP}]
	sci-ml/transformers[${PYTHON_SINGLE_USEDEP}]
	sci-ml/torchao[${PYTHON_SINGLE_USEDEP}]
	sci-ml/trl[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/hf-transfer[${PYTHON_USEDEP}]
		dev-python/filelock[${PYTHON_USEDEP}]
		dev-python/msgspec[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/protobuf[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/regex[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		dev-python/tyro[${PYTHON_USEDEP}]
		dev-python/typing-extensions[${PYTHON_USEDEP}]
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

# Upstream tests require network, GPUs, and several optional ML packages.
RESTRICT="test"

src_prepare() {
	default

	eapply "${FILESDIR}/${PN}-9999-torch-live-version.patch"
	# shmem estimator can't prove configs safe; always add fallbacks
	eapply "${FILESDIR}/${PN}-9999-flex-bwd-always-fallback.patch"
	# don't pass TRL's frozen "ref" adapter tensors to vLLM
	eapply "${FILESDIR}/${PN}-9999-vllm-lora-skip-ref-adapter.patch"
	# gate/up duplication + aliased-buffer scaling tripwire (bug (c))
	eapply "${FILESDIR}/${PN}-9999-vllm-lora-direct-load-fixes.patch"

	rm -rf scripts || die
	rm -rf tests || die
}

pkg_postinst() {
	elog "Unsloth Zoo was installed from live git."
	elog "The pwr overlay now declares the GRPO-related Python deps."
	elog "sci-ml/torchao defaults to Python-only; enable USE=cpp to try its native extensions."
}
