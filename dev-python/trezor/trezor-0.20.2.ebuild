# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit
PYTHON_COMPAT=( python3_{12..15} )
inherit distutils-r1 pypi shell-completion

DESCRIPTION="Python library and trezorctl CLI for Trezor hardware wallets"
HOMEPAGE="https://github.com/trezor/trezor-firmware/tree/main/python https://pypi.org/project/trezor/"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# hidapi is the upstream "hidapi" extra, but it is what the HID transport
# (Trezor One with firmware >= 1.8) imports at runtime — keep it hard.
RDEPEND="
	app-crypt/trezor-udev-rules
	>=dev-python/click-8[${PYTHON_USEDEP}]
	>=dev-python/construct-2.9[${PYTHON_USEDEP}]
	>=dev-python/construct-classes-0.1.2[${PYTHON_USEDEP}]
	>=dev-python/cryptography-47[${PYTHON_USEDEP}]
	>=dev-python/hidapi-0.7.99[${PYTHON_USEDEP}]
	>=dev-python/keyring-25.7.0[${PYTHON_USEDEP}]
	>=dev-python/libusb1-1.6.4[${PYTHON_USEDEP}]
	>=dev-python/mnemonic-0.20[${PYTHON_USEDEP}]
	>=dev-python/noiseprotocol-0.3.1[${PYTHON_USEDEP}]
	<dev-python/noiseprotocol-0.4.0[${PYTHON_USEDEP}]
	>=dev-python/platformdirs-4.4.0[${PYTHON_USEDEP}]
	>=dev-python/requests-2.4.0[${PYTHON_USEDEP}]
	>=dev-python/shamir-mnemonic-0.3.0[${PYTHON_USEDEP}]
	>=dev-python/slip10-1.0.1[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.7.1[${PYTHON_USEDEP}]
"

# Most of the test tree drives physical devices; the hw-independent subset
# still wants extras (stellar-sdk, web3) we do not package.
RESTRICT="test"

python_install_all() {
	distutils-r1_python_install_all
	newbashcomp bash_completion.d/trezorctl.sh trezorctl
}
