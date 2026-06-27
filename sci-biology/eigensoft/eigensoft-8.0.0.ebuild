# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Population genetics tools: smartpca, convertf, mergeit (EIGENSOFT)"
HOMEPAGE="https://github.com/DReichLab/EIG"
SRC_URI="https://github.com/DReichLab/EIG/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/EIG-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	sci-libs/gsl
	|| ( sci-libs/flexiblas sci-libs/openblas )
"
RDEPEND="${DEPEND}"

src_prepare() {
	# Zastąp -I/usr/include/openblas ścieżką flexiblas (Gentoo)
	# lapacke_mangling.h wymaga flexiblas_fortran_mangle.h z /usr/include/flexiblas/
	sed -i \
		-e 's|-I/usr/include/openblas|-I/usr/include/openblas -I/usr/include/flexiblas|g' \
		src/Makefile || die
	default
}

src_compile() {
	cd src || die
	emake OPTIMIZE=1
}

src_install() {
	cd src || die
	emake install
	cd .. || die
	local f
	for f in bin/*; do
		[[ -f "${f}" && "${f}" != *".gitignore" ]] && dobin "${f}"
	done
	dodoc README
}

pkg_postinst() {
	elog "Zainstalowane programy: smartpca, convertf, mergeit, eigenstrat,"
	elog "twstats, smarteigenstrat, smartrel, pca, pcatoy, baseprog"
	elog ""
	elog "Dokumentacja: /usr/share/doc/${PF}/"
	elog "Przykłady: POPGEN/, CONVERTF/, EIGENSTRAT/ w źródłach"
	elog ""
	elog "Można zainstalować razem z sci-biology/admixtools — convertf/mergeit"
	elog "będą dostarczane wyłącznie przez ten pakiet (admixtools ich nie instaluje)."
}
