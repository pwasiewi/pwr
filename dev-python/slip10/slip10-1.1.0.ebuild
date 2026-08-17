# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{12..15} )
inherit distutils-r1 pypi

DESCRIPTION="SLIP-0010 hierarchical deterministic key derivation"
HOMEPAGE="https://github.com/trezor/python-slip10 https://pypi.org/project/slip10/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="dev-python/cryptography[${PYTHON_USEDEP}]"

# The sdist ships no tests.
RESTRICT="test"
