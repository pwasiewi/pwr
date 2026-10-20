# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Clean up the public namespace of a Python package (Keras dependency)"
HOMEPAGE="https://github.com/fchollet/namex https://pypi.org/project/namex/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
