# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="ctypes bindings for hidapi (the 'hid' module used by qmk console)"
HOMEPAGE="https://github.com/apmorton/pyhidapi https://pypi.org/project/hid/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# This package and dev-python/hidapi (Cython bindings, needed by
# dev-python/trezor) both install a top-level Python module named "hid" with
# incompatible APIs (hid.Device vs hid.device). The package directory shadows
# the .so at import time and silently breaks trezor, so they cannot coexist.
RDEPEND="
	dev-libs/hidapi
	!!dev-python/hidapi
"
