# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="GLIMPSE2: genotype imputation and phasing for low-coverage sequencing"
HOMEPAGE="https://odelaneau.github.io/GLIMPSE/"
SRC_URI="https://github.com/odelaneau/GLIMPSE/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.gh.tar.gz"
S="${WORKDIR}/GLIMPSE-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# The makefile adds -mavx2 -mfma for the `phase' tool itself (ifeq NAME,phase);
# upstream documents AVX2 as a hard requirement for GLIMPSE2.
DEPEND="
	app-arch/bzip2:=
	app-arch/xz-utils
	dev-libs/boost:=
	dev-libs/openssl:=
	net-misc/curl:=
	sci-libs/htslib:=
	virtual/zlib
"
RDEPEND="${DEPEND}"

# One self-contained subproject per binary, each with its own makefile.
GLIMPSE_TOOLS=( chunk concordance ligate phase split_reference )

src_prepare() {
	default

	local t
	for t in "${GLIMPSE_TOOLS[@]}"; do
		# 1. respect the toolchain and the user's flags (upstream pins -O3)
		# 2. every build target (system, desktop, docker, ...) hardcodes the
		#    author's home directory and Debian multiarch STATIC libraries; patch
		#    the path variables for all of them, not just one, because the default
		#    goal is the first target in the file (`system'), not `all'
		sed -i \
			-e "s|^CXX=g++ |CXX=$(tc-getCXX) |" \
			-e "s|^CXXFLAG=-O3 |CXXFLAG=${CXXFLAGS} |" \
			-e "s|^LDFLAG=-O3|LDFLAG=${LDFLAGS}|" \
			-E \
			-e "s|^([a-z_-]+): HTSSRC=.*|\\1: HTSSRC=${ESYSROOT}/usr|" \
			-e "s|^([a-z_-]+): HTSLIB_INC=.*|\\1: HTSLIB_INC=${ESYSROOT}/usr/include|" \
			-e "s|^([a-z_-]+): HTSLIB_LIB=.*|\\1: HTSLIB_LIB=-lhts|" \
			-e "s|^([a-z_-]+): BOOST_INC=.*|\\1: BOOST_INC=${ESYSROOT}/usr/include|" \
			-e "s|^([a-z_-]+): BOOST_LIB_IO=.*|\\1: BOOST_LIB_IO=-lboost_iostreams|" \
			-e "s|^([a-z_-]+): BOOST_LIB_PO=.*|\\1: BOOST_LIB_PO=-lboost_program_options|" \
			-e "s|^([a-z_-]+): BOOST_LIB_SE=.*|\\1: BOOST_LIB_SE=-lboost_serialization|" \
			"${t}"/makefile || die "sed failed for ${t}"

		# Guard: a silent sed no-op here would build against the author's paths.
		grep -q "srubinac" "${t}"/makefile \
			&& die "${t}/makefile: upstream hardcoded paths still present"
	done
}

src_compile() {
	local t
	for t in "${GLIMPSE_TOOLS[@]}"; do
		# Build `desktop' explicitly: the default goal is `system', which links
		# htslib statically. NOTHING may be passed as a command-line variable
		# here -- that would override the makefile's own `CXXFLAG+=' lines, which
		# is where -D__COMMIT_ID__/-D__COMMIT_DATE__ (used unguarded in the
		# sources) and phase's -mavx2 -mfma come from.
		emake -C "${t}" desktop
	done
}

src_install() {
	local t
	for t in "${GLIMPSE_TOOLS[@]}"; do
		dobin "${t}/bin/GLIMPSE2_${t}"
	done
	dodoc README.md
	docinto maps
	dodoc -r maps/.
}
