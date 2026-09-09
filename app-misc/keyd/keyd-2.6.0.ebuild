# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Imported from ::guru (app-misc/keyd-2.6.0) with four fixes, see the pwr commit:
#   - the makefile patch is regenerated against 2.6.0 (guru still ships the 2.5.0
#     one, which only applies because patch(1) forgives one line of fuzz)
#   - the systemd unit no longer depends on whether the BUILD host runs systemd
#     (upstream tests `-e /run/systemd/system` in the install target, so a chroot
#     or catalyst build silently drops it from the binpkg) — USE=systemd decides
#   - upstream's data/sysusers.d is dropped: acct-group/keyd owns the group
#   - docs no longer end up nested in /usr/share/doc/${PF}/keyd/

EAPI=8

inherit linux-info

DESCRIPTION="A key remapping daemon for linux"
HOMEPAGE="https://github.com/rvaiya/keyd"
SRC_URI="https://github.com/rvaiya/keyd/archive/v${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
# Deliberately NOT '+systemd': targets/systemd sets USE="systemd udev", so the
# flag follows the image's profile on its own — on for the hardened amd64
# images, off for the OpenRC Pi ones — and neither has to override it.
IUSE="systemd"

RDEPEND="acct-group/keyd"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}"/${P}-makefile.patch
)

pkg_pretend() {
	if ! linux_config_exists; then
		eerror "Unable to check your kernel for user level driver support."
	else
		CONFIG_CHECK="~INPUT_UINPUT"
		ERROR_INPUT_UINPUT="You will need user level driver support"
		ERROR_INPUT_UINPUT+=" (INPUT_UINPUT) compiled into your kernel"
		ERROR_INPUT_UINPUT+=" or loaded as a module to use this package."

		check_extra_config
	fi
}

src_install() {
	# FORCE_SYSTEMD is the only thing the patched install target looks at, so the
	# unit is a property of USE rather than of the machine doing the build.
	emake DESTDIR="${D}" FORCE_SYSTEMD="$(usex systemd 1 '')" install
	einstalldocs

	newinitd "${FILESDIR}/keyd.initd" "keyd"

	# `emake install` writes upstream's docs to /usr/share/doc/keyd while
	# einstalldocs has already created /usr/share/doc/${PF} from DOCS, so a plain
	# rename nests them one level too deep. Fold the contents in instead.
	mv "${ED}"/usr/share/doc/keyd/* "${ED}"/usr/share/doc/${PF}/ || die
	rmdir "${ED}"/usr/share/doc/keyd || die

	# upstream ships these pre-gzipped
	docompress -x /usr/share/man/man1/keyd.1.gz
	docompress -x /usr/share/man/man1/keyd-application-mapper.1.gz

	insinto /etc/keyd
	doins "${FILESDIR}"/default.conf
}

pkg_postinst() {
	elog "Configuration lives in /etc/keyd/default.conf; examples are in"
	elog "  /usr/share/doc/${PF}/examples/"
	elog "keyd grabs every keyboard it matches, so a broken config can lock you"
	elog "out of the console. Keep a second way in (ssh, another TTY) the first"
	elog "time you start it, and validate with:  keyd check"
	if use systemd; then
		elog "Enable with:  systemctl enable --now keyd"
	else
		elog "Enable with:  rc-update add keyd default && rc-service keyd start"
	fi
}
