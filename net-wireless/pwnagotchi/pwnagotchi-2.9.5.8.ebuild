# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 systemd

DESCRIPTION="Raspberry Pi instrumenting bettercap for WiFi handshake capture"
HOMEPAGE="
	https://pwnagotchi.org/
	https://github.com/jayofelony/pwnagotchi
"
SRC_URI="
	https://github.com/jayofelony/${PN}/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="GPL-3"
SLOT="0"
# Pure Python, but the whole point is Pi GPIO/SPI hardware; arm64 is the real
# target (Zero 2 W / 3 / 4 / 5), amd64 only makes sense for --manual runs and
# for developing plugins off-device.
KEYWORDS="~amd64 ~arm64"

# Derived from the imports actually reached from cli.py, because upstream's
# pyproject list is wrong in both directions for 2.9.5.8. Named there but
# imported by no file in the tree: tweepy, smbus2, rpi-lgpio, rpi_hardware_pwm,
# pisugar. Imported at module scope but NOT declared: prctl (plugins/__init__.py
# labels its plugin threads with prctl.set_name), which is a hard requirement --
# pwnagotchi.plugins is on the import path of every run.
# Everything display- or peripheral-related is lazily imported inside
# pwnagotchi.ui.hw.display_for() and the plugins, keyed off config -- they are
# listed in pkg_postinst instead.
RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/dbus-python[${PYTHON_USEDEP}]
		dev-python/file-read-backwards[${PYTHON_USEDEP}]
		dev-python/flask[${PYTHON_USEDEP}]
		dev-python/flask-cors[${PYTHON_USEDEP}]
		dev-python/flask-wtf[${PYTHON_USEDEP}]
		dev-python/pycryptodome[${PYTHON_USEDEP}]
		dev-python/python-dateutil[${PYTHON_USEDEP}]
		dev-python/python-prctl[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/setuptools[${PYTHON_USEDEP}]
		dev-python/tomlkit[${PYTHON_USEDEP}]
		dev-python/websockets[${PYTHON_USEDEP}]
		net-analyzer/scapy[${PYTHON_USEDEP}]
	')
	net-wireless/iw
	sys-apps/iproute2
	net-wireless/pwnagotchi-bettercap
	net-wireless/pwnagotchi-caplets
	net-wireless/pwnagotchi-pwngrid
"

# Upstream ships no test suite -- only the pi-gen image scaffolding under
# stage3/, which is not ours to run.
RESTRICT="test"

src_prepare() {
	# webcfg is enabled by default in defaults.toml and imports the dev-python/toml
	# module at line 3, but never calls it -- the only other 'toml' hits in that
	# file are the /etc/pwnagotchi/config.toml path strings. dev-python/toml was
	# last-rited from ::gentoo (deprecated in favour of tomllib/tomlkit), so the
	# vestigial import would knock out the web config UI for no reason: the plugin
	# loader catches the ImportError per-plugin and only logs a warning.
	# Guarded so this fails loudly if upstream ever starts using the module here.
	grep -q '^import toml$' pwnagotchi/plugins/default/webcfg.py ||
		die "webcfg.py no longer has a bare 'import toml' -- recheck whether it now USES toml"
	if grep -q 'toml\.' pwnagotchi/plugins/default/webcfg.py; then
		die "webcfg.py now calls toml.* -- the import is no longer vestigial, add a real dependency"
	fi
	sed -i '/^import toml$/d' pwnagotchi/plugins/default/webcfg.py || die

	distutils-r1_src_prepare
}

python_install_all() {
	distutils-r1_python_install_all

	# Monitor-mode helpers. defaults.toml points main.mon_{start,stop}_cmd at
	# /usr/bin/monstart and /usr/bin/monstop, which live in upstream's pi-gen
	# stage3 patches rather than in the Python package, so on a plain install
	# those paths are simply absent. Ours are driver-agnostic (see the header
	# in files/monstart) and live under libexec -- "monstart" is far too generic
	# a name to claim in /usr/bin.
	exeinto /usr/libexec/${PN}
	doexe "${FILESDIR}"/monstart "${FILESDIR}"/monstop

	# Config lives where cli.py's --user-config default points. The reference
	# defaults.toml is read out of the installed package directory, never from
	# /etc, so only the user's overlay file belongs here -- it ships as
	# .example because an empty main.iface is not a working configuration.
	local example="${T}"/config.toml.example
	cp pwnagotchi/defaults.toml "${example}" || die
	sed -i \
		-e "s|\"/usr/bin/monstart\"|\"/usr/libexec/${PN}/monstart\"|" \
		-e "s|\"/usr/bin/monstop\"|\"/usr/libexec/${PN}/monstop\"|" \
		-e "s|\"/etc/${PN}/log/|\"/var/log/${PN}/|g" \
		"${example}" || die
	# Upstream defaults put the logs under /etc; the sed above moves them, so
	# fail loudly rather than shipping an example that writes to /etc.
	grep -q "/var/log/${PN}/${PN}.log" "${example}" ||
		die "log path rewrite missed -- upstream changed [main.log] in defaults.toml"
	grep -q "/usr/libexec/${PN}/monstart" "${example}" ||
		die "mon_start_cmd rewrite missed -- upstream changed main.mon_start_cmd"

	insinto /etc/${PN}
	doins "${example}"
	keepdir /etc/${PN}/conf.d /etc/${PN}/custom-plugins
	keepdir /var/log/${PN}

	# Upstream's own unit runs /usr/bin/pwnagotchi-launcher, which is image-only
	# scaffolding too: it sources /usr/bin/pwnlib and execs
	# /opt/.pwn/bin/pwnagotchi out of their venv. Ours drives the installed
	# entry point directly. OpenRC as well as systemd, because the Pi images
	# this is aimed at are OpenRC.
	systemd_dounit "${FILESDIR}"/${PN}.service
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}

	dodoc README.md
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "bettercap and pwngrid come in as net-wireless/pwnagotchi-bettercap"
		elog "and -pwngrid: jayofelony's forks, not upstream, because that is what"
		elog "this talks to. pwnagotchi drives bettercap over its REST/websocket"
		elog "API and does nothing without it."
		elog
		elog "Copy /etc/${PN}/config.toml.example to /etc/${PN}/config.toml and set"
		elog "at least main.iface to your monitor interface. On non-Broadcom"
		elog "adapters also set main.plugins.fix_services.enabled = false -- that"
		elog "watchdog reloads brcmfmac and will fight a mt76/rtl driver."
		elog
		elog "Run it in the foreground first:  pwnagotchi --manual --debug"
	fi

	# Not optfeature: none of these are packaged for Gentoo, so there is no atom
	# to point at. They are imported lazily -- display drivers from inside
	# pwnagotchi.ui.hw.display_for(), the rest from individual plugins -- so a
	# missing one costs exactly the panel or plugin that needs it, and the
	# plugin loader downgrades the ImportError to a warning. The default
	# ui.display.type is "waveshare_4" (though ui.display.enabled defaults to
	# false), and that panel needs spidev.
	elog "Optional Python modules, none of them in Portage (pip into a venv, or"
	elog "leave the matching display/plugin disabled):"
	elog "  spidev    SPI panels -- most Waveshare and Adafruit e-paper/LCD"
	elog "  gpiozero  GPIO-driven panels and the gpio_buttons plugin"
	elog "  inky      Pimoroni Inky e-paper"
	elog "  smbus     I2C battery plugins: ups_lite, wittypi, pisugarx"
	elog "  toml      only to migrate a legacy dotted-toml config"
}
