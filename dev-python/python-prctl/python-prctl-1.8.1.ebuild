# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{12..15} )

PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="Python interface to the Linux prctl(2) syscall and libcap"
HOMEPAGE="
	https://github.com/seveas/python-prctl
	https://pypi.org/project/python-prctl/
"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# The _prctl extension links libcap; setup.py probes for its headers with cpp
# before building and bails out with a plain message if they are missing.
DEPEND="sys-libs/libcap"
RDEPEND="${DEPEND}"

# Upstream's test_prctl.py exercises the real syscall: it sets the process name,
# drops capabilities and calls prctl(PR_SET_SECUREBITS). Under the Portage
# sandbox that either fails on permissions or, worse, succeeds and mutates the
# build process.
RESTRICT="test"
