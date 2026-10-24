# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

# Upstream publishes release tarballs on its website but carries NO git tags, and
# the website's own download URLs are unstable (404 at the time of packaging), so
# this pins the commit. 1.2.4 is the version upstream's website calls current;
# _pYYYYMMDD is the commit date of ${EGIT_COMMIT}.
EGIT_COMMIT="b54ede259cbb0be095bc9c9a8bd18cdaf7e88b74"
MY_PV="${PV%_p*}"

DESCRIPTION="Estimate genome-wide genealogies with recombination for thousands of samples"
HOMEPAGE="https://myersgroup.github.io/relate/
	https://github.com/MyersGroup/relate"
SRC_URI="https://github.com/MyersGroup/relate/archive/${EGIT_COMMIT}.tar.gz
	-> ${P}.gh.tar.gz"
S="${WORKDIR}/relate-${EGIT_COMMIT}"

# Academic, non-commercial, redistribution forbidden -- see licenses/RELATE-academic.
LICENSE="RELATE-academic"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror bindist"

# tskit and gzstream are bundled in include/; no system copies are used.
DEPEND="virtual/zlib"
RDEPEND="${DEPEND}
	app-shells/bash"

RELATE_BINS=(
	Relate RelateFileFormats RelateExtract RelateTreeView
	RelateCoalescentRate RelateSelection RelateMutationRate
)

src_prepare() {
	# 1. upstream pins -O3 and discards the user's flags
	# 2. CMAKE_BINARY_DIR is redirected into the source tree, so the binaries land
	#    in ${S}/bin regardless of the out-of-source build cmake.eclass sets up
	# 3. a POST_BUILD custom command runs the unit tests during compile; move that
	#    to src_test instead
	sed -i \
		-e '/set(CMAKE_CXX_FLAGS "-O3")/d' \
		-e '/add_custom_command(TARGET Tests/d' \
		CMakeLists.txt || die
	grep -q 'CMAKE_CXX_FLAGS "-O3"' CMakeLists.txt \
		&& die "CMakeLists.txt: -O3 override not removed"

	cmake_src_prepare
}

src_test() {
	"${S}"/bin/Tests || die "unit tests failed"
}

src_install() {
	local b
	for b in "${RELATE_BINS[@]}"; do
		dobin "${S}/bin/${b}"
	done

	# Upstream's wrappers expect to find the binaries next to themselves; they are
	# installed as documentation examples rather than on PATH.
	docinto scripts
	dodoc -r scripts/.
	dodoc README.md
	dodoc 20180411_15670_RELATE_Academic_Usage_Licence.pdf
}
