# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit
PYTHON_COMPAT=( python3_{12..15} )
inherit distutils-r1 pypi

DESCRIPTION="Parse binary structs into dataclasses on top of construct"
HOMEPAGE="https://github.com/matejcik/construct-classes https://pypi.org/project/construct-classes/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND=">=dev-python/construct-2.10[${PYTHON_USEDEP}]"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest
