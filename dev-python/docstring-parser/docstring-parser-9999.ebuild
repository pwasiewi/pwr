# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
DISTUTILS_USE_PEP517=hatchling
inherit distutils-r1 git-r3

DESCRIPTION="Parse Python docstrings in reST, Google, and Numpydoc format"
HOMEPAGE="https://github.com/rr-/docstring_parser"
EGIT_REPO_URI="https://github.com/rr-/docstring_parser.git"
EGIT_BRANCH="master"

LICENSE="MIT"
SLOT="0"

# Tests are not needed for this dependency shim in the local ML overlay.
RESTRICT="test"
