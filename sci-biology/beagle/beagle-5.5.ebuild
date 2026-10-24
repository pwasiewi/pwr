# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Copied from the ::science overlay (sci-biology/beagle-5.1) and bumped to 5.5.
# Changes: current 27Feb25.75f jar, bref3 converter added, sci-biology/conform-gt
# dropped from RDEPEND: it is not packaged in ::gentoo, ::stuff or ::pwr, and
# conform-gt is only needed to pre-align a VCF to the reference panel.

EAPI=8

inherit java-pkg-2

MY_PV="27Feb25.75f"

DESCRIPTION="Genotype calling/phasing, imputation of ungenotyped markers"
HOMEPAGE="https://faculty.washington.edu/browning/beagle/beagle.html"
SRC_URI="
	https://faculty.washington.edu/browning/beagle/beagle.${MY_PV}.jar
	https://faculty.washington.edu/browning/beagle/bref3.${MY_PV}.jar
	https://faculty.washington.edu/browning/beagle/beagle_${PV}_17Dec24.pdf
	https://faculty.washington.edu/browning/beagle/run.beagle.${MY_PV}.example
		-> ${PN}-${PV}-example.sh
"
S="${WORKDIR}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=virtual/jre-1.8:*"
DEPEND=">=virtual/jdk-1.8:*"

src_install() {
	java-pkg_newjar "${DISTDIR}/beagle.${MY_PV}.jar" "${PN}.jar"
	java-pkg_newjar "${DISTDIR}/bref3.${MY_PV}.jar" bref3.jar
	java-pkg_dolauncher "${PN}" --jar "${PN}.jar"
	java-pkg_dolauncher bref3 --jar bref3.jar
	dodoc "${DISTDIR}/beagle_${PV}_17Dec24.pdf"
	newdoc "${DISTDIR}/${PN}-${PV}-example.sh" "${PN}-example.sh"
}
