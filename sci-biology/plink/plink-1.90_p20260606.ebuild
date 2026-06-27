# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Whole genome association analysis toolset, plink 1.9"
HOMEPAGE="https://www.cog-genomics.org/plink/1.9/"

# Full plink-ng archive includes both 1.9/ source and 2.0/simde/ headers.
# The Makefile for 1.9 expects ../2.0/simde/ (included in this tarball).
# Source is the master branch HEAD from 2026-06-06.
GIT_COMMIT="a81e38220b16e3907bdcedbe6ce39b273e001e13"
MY_PN="plink-ng"
MY_P="${MY_PN}-${GIT_COMMIT}"
SRC_URI="https://github.com/chrchang/plink-ng/archive/${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_P}/1.9"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	virtual/zlib:=
	|| ( sci-libs/flexiblas sci-libs/openblas )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

# Binary name p-link: avoids collision with net-misc/putty ("plink").
# Per Debian and Gentoo upstream discussion, renamed following that precedent.

src_prepare() {
	default
}

src_compile() {
	# 1.9/Makefile uses ?= for CFLAGS/CXXFLAGS; the Portage env CFLAGS takes
	# precedence. We add -I../2.0/simde (needed include, present in this archive).
	# System zlib replaces bundled ../zlib-1.3.2/ via ZLIB override.
	# CXEXTRA ?= -DSTABLE_BUILD is still appended via "CFLAGS += $(CXEXTRA)".
	# Use flexiblas (provides dgemm_ and full BLAS/CBLAS/LAPACK interface).
	# cblas/lapack pkg-config alone skips -lblas → dgemm_ undefined; flexiblas
	# is the single lib that wraps everything (same as eigensoft/admixtools).
	local BLASFLAGS
	if $(tc-getPKG_CONFIG) --exists flexiblas 2>/dev/null; then
		BLASFLAGS="$($(tc-getPKG_CONFIG) --libs flexiblas) -llapack"
	else
		BLASFLAGS="$($(tc-getPKG_CONFIG) --libs lapack blas cblas)"
	fi

	emake \
		CXX="$(tc-getCXX)" \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS} -I../2.0/simde -DSTABLE_BUILD" \
		CXXFLAGS="${CXXFLAGS} -I../2.0/simde -DSTABLE_BUILD" \
		ZLIB="$($(tc-getPKG_CONFIG) --libs zlib)" \
		BLASFLAGS="${BLASFLAGS}" \
		LDFLAGS="${LDFLAGS} -lm -lpthread -ldl"
}

src_install() {
	newbin plink p-link
}

pkg_postinst() {
	elog "plink 1.9 (v1.90b7.11.d, źródło master 2026-06-06) zainstalowany jako 'p-link'."
	elog "Binarna nazwa p-link unika konfliktu z net-misc/putty."
	elog ""
	elog "Używany przez ~/Claude/aadr/03_merge_and_test.sh do --bmerge"
	elog "(plink2 nie obsługuje non-concatenating merge w tej wersji)."
	elog ""
	elog "UWAGA (pitfall #10 z aadr/CLAUDE.md): ten build może nadal segfaultować"
	elog "przy finalnym --make-bed po --bmerge. Skrypt 03_merge_and_test.sh"
	elog "obsługuje to przez użycie pośredniego pliku *-merge.{bed,bim,fam}."
	elog "Jeśli nowy build nie segfaultuje, można usunąć workaround z kroku 3e."
}
