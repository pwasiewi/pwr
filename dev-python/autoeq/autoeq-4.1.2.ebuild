# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )
inherit distutils-r1 pypi

DESCRIPTION="Automatic headphone equalizer config generator"
HOMEPAGE="https://github.com/jaakkopasanen/AutoEq https://pypi.org/project/autoeq/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	dev-python/matplotlib[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
	dev-python/soundfile[${PYTHON_USEDEP}]
	dev-python/tabulate[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]
"

python_prepare_all() {
	# 4.1.2 (2023, still the newest) caps Python at <3.12 and pins numpy~=1.24,
	# scipy~=1.10, matplotlib~=3.7. The pins are stale, not real limits: on
	# Python 3.14 / numpy 2.5 / scipy 1.17 / matplotlib 3.11 it produced the same
	# minimum-phase IR (max 1 LSB of 32768) and the same ParametricEQ as the
	# pinned stack on Python 3.11 (2026-10-09). Drop the cap and the ~= pins;
	# grep afterwards so an upstream change fails loudly instead of silently.
	sed -i -E \
		-e 's/^requires-python = ">=3\.8,<3\.12"/requires-python = ">=3.8"/' \
		-e "s/^(    '[A-Za-z]+)~=[0-9.]+',/\1',/" \
		pyproject.toml || die
	if grep -qE '~=|<3\.12' pyproject.toml; then
		die "pyproject.toml still carries pins — the sed above no longer matches upstream"
	fi
	distutils-r1_python_prepare_all
}

python_install_all() {
	distutils-r1_python_install_all
	# upstream ships no console script — the CLI is 'python -m autoeq'
	cat > "${T}"/autoeq <<-'PYEOF' || die
		#!/usr/bin/env python
		import runpy
		runpy.run_module("autoeq", run_name="__main__", alter_sys=True)
	PYEOF
	python_foreach_impl python_newscript "${T}"/autoeq autoeq
}
