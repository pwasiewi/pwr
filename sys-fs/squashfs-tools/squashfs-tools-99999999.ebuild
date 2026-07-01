# Copyright 1999-2026 Gentoo Authors and Martin Väth
# Distributed under the terms of the GNU General Public License v2

EAPI=9
inherit flag-o-matic toolchain-funcs

DESCRIPTION="Tool for creating compressed filesystem type squashfs"
HOMEPAGE="https://github.com/plougher/squashfs-tools/"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug lz4 lzma lzo static xattr +xz +zstd"

case ${PV} in
*9999)
	PROPERTIES="live"
	EGIT_REPO_URI="file:///home/pwas/Claude/testons/squashfs-tools"
	inherit git-r3
	SRC_URI=""
	KEYWORDS=""
src_unpack() {
	git-r3_src_unpack
};;
*)
	RESTRICT="mirror"
	SRC_URI="https://github.com/plougher/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz";;
esac

S="${WORKDIR}/${P}/${PN}"

LIB_DEPEND="
	sys-libs/zlib:=[static-libs(+)]
	lz4? ( app-arch/lz4:=[static-libs(+)] )
	lzma? ( app-arch/xz-utils:=[static-libs(+)] )
	lzo? ( dev-libs/lzo:=[static-libs(+)] )
	xattr? ( sys-apps/attr:=[static-libs(+)] )
	xz? ( app-arch/xz-utils:=[static-libs(+)] )
	zstd? ( >=app-arch/zstd-1.0:=[static-libs(+)] )
"
RDEPEND="!static? ( ${LIB_DEPEND//\[static-libs(+)]} )"
DEPEND="${RDEPEND}
	static? ( ${LIB_DEPEND} )"

src_prepare() {
	sed -i -e 's/^#ifndef linux$/#if !defined(linux) \&\& !defined(__GLIBC__)/' \
		-- "${S}"/*.c "${S}"/*.h || die
	# upstream commit e9875f25 introduced static_deps: test.c without adding test.c
	echo "int main(void){return 0;}" > "${S}/test.c" || die
	default
}

use10() {
	usex "$1" 1 0
}

src_configure() {
	EMAKE_SQUASHFS_CONF=(
		LZMA_XZ_SUPPORT=$(use10 lzma)
		LZO_SUPPORT=$(use10 lzo)
		LZ4_SUPPORT=$(use10 lz4)
		XATTR_SUPPORT=$(use10 xattr)
		XZ_SUPPORT=$(use10 xz)
		ZSTD_SUPPORT=$(use10 zstd)
	)
	filter-flags -fno-common
	tc-export CC
	use debug && append-cppflags -DSQUASHFS_TRACE
	use static && append-ldflags -static
}

src_compile() {
	emake "${EMAKE_SQUASHFS_CONF[@]}"
}

src_install() {
	dobin mksquashfs unsquashfs
	dosym mksquashfs /usr/bin/sqfstar
	dosym unsquashfs /usr/bin/sqfscat
	doman "${S}/../Documentation/manpages"/*.1
	cd "${S}/.." || die
	dodoc ACKNOWLEDGEMENTS CHANGES CHANGES.md README README.md SECURITY.md USAGE
}
