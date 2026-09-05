# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Colored symbols for various log levels (port of log-symbols), used by halo"
HOMEPAGE="https://github.com/manrajgrover/py-log-symbols https://pypi.org/project/log-symbols/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=dev-python/colorama-0.3.9[${PYTHON_USEDEP}]"
