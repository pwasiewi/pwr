# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit java-pkg-2

# Upstream versions its jars by date: refined-ibd.17Jan20.102.jar. PV is that date
# in a Gentoo-sortable form plus upstream's build number.
MY_PV="17Jan20.102"

DESCRIPTION="Detection of identity-by-descent segments in phased genotype data"
HOMEPAGE="https://faculty.washington.edu/browning/refined-ibd.html"
SRC_URI="
	https://faculty.washington.edu/browning/refined-ibd/refined-ibd.${MY_PV}.jar
	https://faculty.washington.edu/browning/refined-ibd/merge-ibd-segments.${MY_PV}.jar
	https://faculty.washington.edu/browning/refined-ibd/refined-ibd.04Dec18.pdf
"
S="${WORKDIR}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=virtual/jre-1.8:*"
DEPEND=">=virtual/jdk-1.8:*"

src_install() {
	java-pkg_newjar "${DISTDIR}/refined-ibd.${MY_PV}.jar" "${PN}.jar"
	java-pkg_newjar "${DISTDIR}/merge-ibd-segments.${MY_PV}.jar" merge-ibd-segments.jar
	java-pkg_dolauncher "${PN}" --jar "${PN}.jar"
	java-pkg_dolauncher merge-ibd-segments --jar merge-ibd-segments.jar
	dodoc "${DISTDIR}/refined-ibd.04Dec18.pdf"
}
