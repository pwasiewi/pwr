# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# jayofelony's fork of bettercap/caplets. What makes it not upstream is the
# pwnagotchi-auto and pwnagotchi-manual caplets, which are what
# net-wireless/pwnagotchi-bettercap is started with. The repo carries no tags at
# all, so this is a master snapshot pinned by commit, versioned by its date.
MY_COMMIT="3c90f7871f2c60585ff7c76fb68701ace395285a"

DESCRIPTION="Caplets (bettercap scripts) fork carrying the pwnagotchi caplets"
HOMEPAGE="https://github.com/jayofelony/caplets"
SRC_URI="
	https://github.com/jayofelony/caplets/archive/${MY_COMMIT}.tar.gz
		-> ${P}.gh.tar.gz
"
S="${WORKDIR}/caplets-${MY_COMMIT}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Data only: .cap scripts interpreted by bettercap's own session parser.
RDEPEND="net-wireless/pwnagotchi-bettercap"

# Data only. The default src_compile would run emake, and upstream's Makefile
# has exactly one target -- an 'install' that cp's into /usr/local/share
# outside ${D}. Nothing to build.
src_compile() { :; }

src_install() {
	# Upstream's Makefile does 'cp -rf *' into the caplet directory, which drags
	# the Makefile and README in with it. Install the caplets and their support
	# files, not the repo scaffolding.
	insinto /usr/share/bettercap/caplets
	local f
	for f in *; do
		[[ ${f} == Makefile || ${f} == README.md || ${f} == LICENSE* ]] && continue
		if [[ -d ${f} ]]; then
			doins -r "${f}"
		else
			doins "${f}"
		fi
	done

	[[ -f ${ED}/usr/share/bettercap/caplets/pwnagotchi-auto.cap ]] ||
		die "pwnagotchi-auto.cap did not install -- upstream reorganised the repo"

	dodoc README.md
}
