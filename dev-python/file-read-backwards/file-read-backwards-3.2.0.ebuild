# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1 pypi

DESCRIPTION="Memory efficient way of reading files line-by-line from the end"
HOMEPAGE="
	https://github.com/RobinNil/file_read_backwards
	https://pypi.org/project/file-read-backwards/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Pulled in by net-wireless/pwnagotchi, whose log.py tails the session log
# backwards to find the last session boundary without reading the whole file.
EPYTEST_PLUGINS=()
distutils_enable_tests pytest
