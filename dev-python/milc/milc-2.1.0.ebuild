# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Opinionated batteries-included Python 3 CLI framework (used by qmk)"
HOMEPAGE="https://milc.clueboard.co/ https://github.com/clueboard/milc"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/argcomplete[${PYTHON_USEDEP}]
	dev-python/colorama[${PYTHON_USEDEP}]
	dev-python/halo[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	dev-python/spinners[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"

# The sdist ships tests/ but not the tests/common.py helper they import,
# so the suite cannot even be collected. Nothing to enable.

python_prepare_all() {
	# types-colorama is a stubs-only package for type checkers; it is not
	# packaged in Gentoo and has no runtime role.
	grep -q '"types-colorama",' pyproject.toml ||
		die "types-colorama dependency wiring changed; revisit the sed"
	sed -i '/"types-colorama",/d' pyproject.toml || die
	distutils-r1_python_prepare_all
}
