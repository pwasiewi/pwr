# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="Command-line tool for working with QMK keyboard firmware (qmk_cli)"
HOMEPAGE="https://qmk.fm/ https://github.com/qmk/qmk_cli"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="hid"

# Everything in [options] install_requires of setup.cfg. The firmware
# checkout that 'qmk setup' clones has the same requirements.txt, so the
# tree-side deps are what 'qmk doctor' looks for as well.
RDEPEND="
	dev-vcs/git
	dev-python/dotty-dict[${PYTHON_USEDEP}]
	dev-python/hjson[${PYTHON_USEDEP}]
	>=dev-python/jsonschema-4[${PYTHON_USEDEP}]
	>=dev-python/milc-1.9.0[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	dev-python/pygments[${PYTHON_USEDEP}]
	dev-python/pyserial[${PYTHON_USEDEP}]
	dev-python/pyusb[${PYTHON_USEDEP}]
	hid? ( dev-python/hid[${PYTHON_USEDEP}] )
"

python_prepare_all() {
	if ! use hid; then
		# 'hid' (pyhidapi) is imported lazily by 'qmk console' only
		# (qmk_cli/subcommands/console.py) and cannot coexist with
		# dev-python/hidapi (trezor). Drop it from the wheel metadata so
		# 'pip check' stays clean without USE=hid.
		grep -q -P '^\thid$' setup.cfg ||
			die "install_requires wiring for hid changed; revisit the sed"
		sed -i -e '/^\thid$/d' setup.cfg || die
	fi
	distutils-r1_python_prepare_all
}

pkg_postinst() {
	optfeature "flashing STM32/ARM boards over DFU (Keychron, most 'A' boards)" app-mobilephone/dfu-util
	optfeature "flashing ATmega32U4 boards (Caterina/avrdude bootloaders)" dev-embedded/avrdude
	optfeature "flashing ATmega boards over DFU" dev-embedded/dfu-programmer
	optfeature "building firmware for ARM boards (arm-none-eabi toolchain)" sys-devel/crossdev
	elog "First run: 'qmk setup' clones qmk/qmk_firmware into ~/qmk_firmware."
	elog "For a Keychron HE board use their fork instead:"
	elog "    qmk setup Keychron/qmk_firmware -b <branch>"
	elog "The hidraw/DFU udev rules are in /etc/udev/rules.d/70-keyboards.rules."
}
