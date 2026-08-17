# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{12..15} )
inherit distutils-r1 pypi

DESCRIPTION="Reference implementation of SLIP-0039: Shamir's secret-sharing for mnemonics"
HOMEPAGE="https://github.com/trezor/python-shamir-mnemonic https://pypi.org/project/shamir-mnemonic/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# click is the upstream "cli" extra, but the shamir console script is
# installed unconditionally and imports it.
RDEPEND="dev-python/click[${PYTHON_USEDEP}]"

# The sdist ships no tests.
RESTRICT="test"
