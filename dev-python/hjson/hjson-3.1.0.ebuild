# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Hjson, a user interface for JSON (Python implementation)"
HOMEPAGE="https://github.com/hjson/hjson-py https://pypi.org/project/hjson/"

# based on simplejson: dual-licensed MIT / Academic Free License 2.1
LICENSE="|| ( MIT AFL-2.1 )"
SLOT="0"
KEYWORDS="~amd64"

# The sdist ships hjson/tests/ but not hjson/tests/assets/ (testlist.txt and
# the fixtures), so the suite dies on FileNotFoundError. Nothing to enable
# until upstream ships the assets in the PyPI tarball.
