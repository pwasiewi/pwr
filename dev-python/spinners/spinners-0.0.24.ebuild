# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Spinners for the terminal (port of cli-spinners), used by halo/milc"
HOMEPAGE="https://github.com/manrajgrover/py-spinners https://pypi.org/project/spinners/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
