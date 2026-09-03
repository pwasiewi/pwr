# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::guru stops at 0.12.1 (2025); 0.15.0 (2026-08-14) adds the non-interactive
# CLI mode (--tool/--version/--for) that scripts need. CRATES generated with
# pycargoebuild from the workspace member protonup-rs/.

EAPI=8

RUST_MIN_VER="1.85.0"  # edition = "2024"

CRATES="
	adler2@2.0.1
	aho-corasick@1.1.5
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	anyhow@1.0.104
	arcstr@1.2.0
	assert-json-diff@2.0.2
	astral-tokio-tar@0.6.4
	async-compression@0.4.43
	atomic-waker@1.1.2
	aws-lc-rs@1.18.0
	aws-lc-sys@0.44.0
	base64@0.22.1
	bitflags@2.13.1
	block-buffer@0.12.1
	bumpalo@3.20.3
	bytes@1.12.1
	cc@1.4.2
	cfg-if@1.0.4
	cfg_aliases@0.2.2
	chacha20@0.10.1
	clap@4.6.6
	clap_builder@4.6.6
	clap_complete@4.6.9
	clap_derive@4.6.4
	clap_lex@1.1.0
	cmake@0.1.58
	colorchoice@1.0.5
	combine@4.6.7
	compression-codecs@0.4.38
	compression-core@0.4.32
	console@0.16.4
	const-oid@0.10.2
	core-foundation-sys@0.8.7
	core-foundation@0.10.1
	cpufeatures@0.3.0
	crc32fast@1.5.0
	crypto-common@0.2.2
	deadpool-runtime@0.1.4
	deadpool@0.12.3
	digest@0.11.3
	dirs-sys@0.5.0
	dirs@6.0.0
	displaydoc@0.2.7
	dunce@1.0.5
	dyn-clone@1.0.20
	encode_unicode@1.0.0
	equivalent@1.0.2
	errno@0.3.14
	fastrand@2.5.0
	filetime@0.2.29
	find-msvc-tools@0.1.10
	flate2@1.1.9
	fnv@1.0.7
	form_urlencoded@1.2.2
	fs4@0.13.1
	fs_extra@1.3.0
	futures-channel@0.3.34
	futures-core@0.3.34
	futures-executor@0.3.34
	futures-io@0.3.34
	futures-macro@0.3.34
	futures-sink@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	futures@0.3.34
	getrandom@0.2.17
	getrandom@0.4.3
	h2@0.4.15
	hashbrown@0.17.1
	heck@0.5.0
	hermit-abi@0.5.2
	hex-literal@1.1.0
	hex@0.4.3
	http-body-util@0.1.5
	http-body@1.1.0
	http@1.5.0
	httparse@1.10.1
	httpdate@1.0.3
	hybrid-array@0.4.14
	hyper-rustls@0.27.9
	hyper-util@0.1.20
	hyper@1.11.0
	icu_collections@2.3.0
	icu_locale_core@2.3.0
	icu_normalizer@2.3.0
	icu_normalizer_data@2.3.0
	icu_properties@2.3.0
	icu_properties_data@2.3.0
	icu_provider@2.3.0
	idna@1.1.0
	idna_adapter@1.2.2
	indexmap@2.14.0
	indicatif@0.18.6
	inquire@0.9.4
	ipnet@2.12.1
	is_terminal_polyfill@1.70.2
	itoa@1.0.18
	jni-macros@0.22.4
	jni-sys-macros@0.4.1
	jni-sys@0.4.1
	jni@0.22.4
	jobserver@0.1.35
	js-sys@0.3.104
	lazy_static@1.5.0
	libc@0.2.189
	liblzma-sys@0.4.8
	liblzma@0.4.8
	libredox@0.1.19
	linux-raw-sys@0.12.1
	litemap@0.8.3
	log@0.4.33
	lru-slab@0.1.2
	memchr@2.8.3
	miniz_oxide@0.8.9
	mio@1.2.2
	num_cpus@1.17.0
	numtoa@0.2.4
	once_cell@1.21.4
	once_cell_polyfill@1.70.2
	openssl-probe@0.2.1
	option-ext@0.2.0
	percent-encoding@2.3.2
	pin-project-internal@1.1.13
	pin-project-lite@0.2.17
	pin-project@1.1.13
	pkg-config@0.3.34
	portable-atomic@1.15.0
	potential_utf@0.1.6
	proc-macro2@1.0.107
	quinn-proto@0.11.16
	quinn-udp@0.5.15
	quinn@0.11.11
	quote@1.0.47
	r-efi@6.0.0
	rand@0.10.2
	rand_core@0.10.1
	rand_pcg@0.10.2
	redox_users@0.5.2
	regex-automata@0.4.18
	regex-syntax@0.8.11
	regex@1.13.1
	reqwest@0.13.4
	ring@0.17.14
	ron@0.12.2
	rustc-hash@2.1.3
	rustc_version@0.4.1
	rustix@1.1.4
	rustls-native-certs@0.8.4
	rustls-pki-types@1.15.1
	rustls-platform-verifier-android@0.1.1
	rustls-platform-verifier@0.7.0
	rustls-webpki@0.103.14
	rustls@0.23.43
	rustversion@1.0.23
	same-file@1.0.6
	schannel@0.1.29
	security-framework-sys@2.17.0
	security-framework@3.7.0
	semver@1.0.28
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.151
	sha2@0.11.0
	shlex@2.0.1
	simd-adler32@0.3.10
	simd_cesu8@1.2.0
	simdutf8@0.1.5
	slab@0.4.12
	smallvec@1.15.2
	socket2@0.6.5
	stable_deref_trait@1.2.1
	strsim@0.11.1
	subtle@2.6.1
	syn@2.0.119
	syn@3.0.3
	sync_wrapper@1.0.2
	synstructure@0.13.2
	tar@0.4.46
	tempfile@3.27.0
	termion@4.0.6
	thiserror-impl@2.0.20
	thiserror@2.0.20
	tinystr@0.8.4
	tinyvec@1.12.0
	tinyvec_macros@0.1.1
	tokio-macros@2.7.2
	tokio-rustls@0.26.4
	tokio-stream@0.1.19
	tokio-util@0.7.19
	tokio@1.53.1
	tower-http@0.6.11
	tower-layer@0.3.3
	tower-service@0.3.3
	tower@0.5.3
	tracing-core@0.1.36
	tracing@0.1.44
	try-lock@0.2.5
	typeid@1.0.3
	typenum@1.20.1
	unicode-ident@1.0.24
	unicode-segmentation@1.13.3
	unicode-width@0.2.2
	unit-prefix@0.5.2
	untrusted@0.9.0
	url@2.5.8
	utf8_iter@1.0.4
	utf8parse@0.2.2
	walkdir@2.5.0
	want@0.3.1
	wasi@0.11.1+wasi-snapshot-preview1
	wasm-bindgen-futures@0.4.77
	wasm-bindgen-macro-support@0.2.127
	wasm-bindgen-macro@0.2.127
	wasm-bindgen-shared@0.2.127
	wasm-bindgen@0.2.127
	wasm-streams@0.5.0
	web-sys@0.3.104
	web-time@1.1.0
	webpki-root-certs@1.0.9
	winapi-util@0.1.11
	windows-link@0.2.1
	windows-sys@0.52.0
	windows-sys@0.59.0
	windows-sys@0.61.2
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.52.6
	wiremock@0.6.5
	writeable@0.6.4
	xattr@1.6.1
	yoke-derive@0.8.2
	yoke@0.8.3
	zerofrom-derive@0.1.7
	zerofrom@0.1.8
	zeroize@1.9.0
	zerotrie@0.2.5
	zerovec-derive@0.11.4
	zerovec@0.11.7
	zmij@1.0.23
	zstd-safe@7.2.4
	zstd-sys@2.0.16+zstd.1.5.7
	zstd@0.13.3
"

inherit cargo shell-completion

DESCRIPTION="Installer and updater for Linux gaming compatibility tools (GE-Proton, DXVK…)"
HOMEPAGE="https://github.com/auyer/Protonup-rs"
SRC_URI="
	https://github.com/auyer/Protonup-rs/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/Protonup-rs-${PV}"

LICENSE="GPL-3"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0
"
SLOT="0"
KEYWORDS="~amd64"

# aws-lc-sys (rustls' default crypto provider in reqwest 0.13) builds with cmake
BDEPEND="dev-build/cmake"

QA_FLAGS_IGNORED="usr/bin/protonup-rs"

src_compile() {
	cargo_src_compile -p protonup-rs
}

src_install() {
	cargo_src_install --path ./protonup-rs
	doman protonup-rs/man/protonup-rs.1
	# build.rs writes these next to the crate at build time
	newbashcomp protonup-rs/completions/protonup-rs.bash protonup-rs
	dozshcomp protonup-rs/completions/_protonup-rs
	dofishcomp protonup-rs/completions/protonup-rs.fish
	dodoc README.md
}

pkg_postinst() {
	elog "Non-interactive use (what steamctl documents):"
	elog "  protonup-rs --tool GEProton --version latest --for steam"
	elog "  protonup-rs --tool GEProton --version 11-6 --for ~/.steam/root/compatibilitytools.d"
	elog "Bare 'protonup-rs' opens the TUI menu; -q is quick mode."
}
