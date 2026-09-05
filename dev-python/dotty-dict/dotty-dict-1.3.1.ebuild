# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Dictionary wrapper for quick access to deeply nested keys"
HOMEPAGE="https://github.com/pawelzny/dotty_dict https://pypi.org/project/dotty-dict/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
