# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Population genetics tools: qpAdm, qpGraph, qpWave, qp3Pop, qpDstat (ADMIXTOOLS)"
HOMEPAGE="https://github.com/DReichLab/AdmixTools"
SRC_URI="https://github.com/DReichLab/AdmixTools/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/AdmixTools-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	sci-libs/gsl
	|| ( sci-libs/flexiblas sci-libs/openblas )
"
RDEPEND="${DEPEND}"

src_prepare() {
	cd src || die
	# Usuwamy flagi profilowania/debug; dodajemy -std=gnu17 bo GCC 15 traktuje
	# pusty void foo() jako void foo(void) (C23), co koliduje z deklaracjami K&R
	sed -i \
		-e 's/override CFLAGS += -c -g -p -pg/override CFLAGS += -c -std=gnu17/' \
		-e 's/override LDFLAGS += -g  -p -pg/override LDFLAGS +=/' \
		Makefile || die
	cd .. || die
	default
}

src_compile() {
	cd src || die
	emake OPTIMIZE=1 all
}

src_install() {
	cd src || die

	# Główne narzędzia qp*
	local qptools=(
		qp3Pop qpDstat qpF4ratio qpAdm qpWave
		qp4diff dowtjack qpBound qpGraph qpreroot
		qpff3base qpDpart qpfstats qpfmv qpmix
	)
	dobin "${qptools[@]}"

	# Narzędzia pomocnicze
	# convertf i mergeit celowo pominięte — dostarcza sci-biology/eigensoft
	local helpers=( snpunion simpjack2 grabpars easystats easycheck easylite
		multimerge geno_single transpose merge_transpose nickhash )
	dobin "${helpers[@]}"

	# Skrypty perl/R z perlsrc/
	cd .. || die
	local f
	for f in perlsrc/*; do
		[[ -f "${f}" ]] && dobin "${f}"
	done

	# Tablice danych
	insinto /usr/share/admixtools
	doins src/twtable

	# Skrypty pomocnicze
	[[ -d src/script ]] && dobin src/script/*

	dodoc README README.3PopTest README.Dstatistics README.F4RatioTest \
		README.QPGRAPH README.QpWave README.qpfstats README.CONVERTF \
		README.ROLLOFF README.ROLLOFF_OUTPUT README.INSTALL README.REXPFIT \
		README.qp4diff
}

pkg_postinst() {
	elog "Zainstalowane programy: qpAdm, qpGraph, qpWave, qp3Pop, qpDstat,"
	elog "qpF4ratio, qpBound, qpff3base, qpfstats i inne."
	elog ""
	elog "convertf i mergeit: dostarczane przez sci-biology/eigensoft."
	elog "smartpca: dostarczane przez sci-biology/eigensoft."
	elog ""
	elog "Tablice D-statystyk: /usr/share/admixtools/twtable"
}
