# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1 git-r3

DESCRIPTION="Train transformer language models with reinforcement learning"
HOMEPAGE="https://github.com/huggingface/trl https://huggingface.co/docs/trl"
EGIT_REPO_URI="https://github.com/huggingface/trl.git"
EGIT_BRANCH="main"

LICENSE="Apache-2.0"
SLOT="0"

RDEPEND="
	>=sci-ml/accelerate-1.4.0[${PYTHON_SINGLE_USEDEP}]
	>=sci-ml/datasets-4.7.0[${PYTHON_SINGLE_USEDEP}]
	>=sci-ml/transformers-4.56.2[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/jinja2[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"

# Test suite requires network, model downloads, and optional backends.
RESTRICT="test"

# (grpo-ref-adapter-dtype.patch retired 2026-11-02: it deleted the
# `ref_param.data.copy_(param.data)` line that unsloth's ref-adapter strip
# anchors on, so beta != 0 runs under unsloth still built the "ref" adapter;
# its second hunk also stopped applying at TRL >= 1.15. Pin: env/trl-git-pin.conf.)

pkg_postinst() {
	elog "TRL optional integrations for this Unsloth GRPO setup include:"
	elog "  sci-ml/peft, dev-python/vllm, dev-python/bitsandbytes"
	elog "Those are already expected from sci-ml/unsloth in the pwr overlay."
}
