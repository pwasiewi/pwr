# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Whole genome association analysis toolset, plink2 prebuilt binary (alpha7)"
HOMEPAGE="https://www.cog-genomics.org/plink/2.0/"
SRC_URI="
	avx2? (
		https://s3.amazonaws.com/plink2-assets/alpha7/plink2_linux_avx2_${PV}.zip
			-> ${P}-avx2.zip
	)
	!avx2? (
		https://s3.amazonaws.com/plink2-assets/alpha7/plink2_linux_x86_64_${PV}.zip
			-> ${P}-x86_64.zip
	)
"

S="${WORKDIR}"

LICENSE="GPL-3 Intel-ISSL"
SLOT="0"
KEYWORDS="-* ~amd64"

IUSE="+avx2"

# Intel-ISSL zabrania redystrybucji i modyfikacji binarki
# strip: binarki statycznie linkowane, strip zepsułby build ID
RESTRICT="bindist mirror strip"

BDEPEND="app-arch/unzip"

QA_PREBUILT="usr/bin/plink2 usr/bin/vcf_subset"

src_install() {
	dobin plink2
	[[ -f vcf_subset ]] && dobin vcf_subset
	dodoc intel-simplified-software-license.txt
}

pkg_postinst() {
	elog "plink2 zainstalowane z oficjalnych buildów alpha7 (${PV})."
	elog ""
	if use avx2; then
		elog "Wariant: AVX2 (Zen 2+ / Haswell+) — zoptymalizowany"
	else
		elog "Wariant: x86_64 generic (SSE2 baseline)"
		elog "Dla lepszej wydajności: emerge plink2-bin[avx2]"
	fi
	elog ""
	elog "Dokumentacja: https://www.cog-genomics.org/plink/2.0/"
	elog "Nowe buildy alpha7: https://s3.amazonaws.com/plink2-assets/alpha7/"
}
