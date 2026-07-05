# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_USE_PEP517=hatchling
inherit distutils-r1 git-r3

DESCRIPTION="CLI interfaces and config objects from Python type annotations"
HOMEPAGE="https://github.com/brentyi/tyro https://brentyi.github.io/tyro/"
EGIT_REPO_URI="https://github.com/brentyi/tyro.git"
EGIT_BRANCH="main"

LICENSE="MIT"
SLOT="0"

RDEPEND="
	>=dev-python/docstring-parser-0.16[${PYTHON_USEDEP}]
	>=dev-python/typeguard-4.0.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.13.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

# Upstream tests cover many optional integrations and generated fixtures.
RESTRICT="test"
