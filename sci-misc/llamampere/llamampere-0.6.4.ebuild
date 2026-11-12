# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake cuda flag-o-matic toolchain-funcs

MY_PN="llamAmpere"

DESCRIPTION="llama.cpp fork tuned for Qwen3.8 (MTP, Flash-Next expert split) on NVIDIA cards"
HOMEPAGE="https://github.com/JakeATX/llamAmpere"
SRC_URI="https://github.com/JakeATX/${MY_PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

CPU_FLAGS_X86=(
	avx avx2 avx512_bf16 avx512_vnni avx512f avx512vbmi avx_vnni bmi2 f16c
	fma3 sse4_2
)

IUSE="+cuda debug +openmp +openssl"
IUSE+=" ${CPU_FLAGS_X86[@]/#/cpu_flags_x86_}"

# The backend test needs the GPU and the other suites need model files.
RESTRICT="test"

DEPEND="
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
	openmp? ( llvm-runtimes/openmp:= )
	openssl? ( dev-libs/openssl:= )
"
RDEPEND="${DEPEND}"
BDEPEND="cuda? ( dev-util/nvidia-cuda-toolkit )"

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	# cuda.eclass exports a src_prepare that dies without the toolkit.
	use cuda && cuda_src_prepare
	cmake_src_prepare

	# The launcher expects a source checkout with build/bin; point it at
	# the installed layout. The grep guards a silent no-op after a bump.
	grep -q 'repo/build/bin/llama-server' scripts/flash-next-server.sh ||
		die "flash-next-server.sh: default server path changed"
	sed -i 's|\$repo/build/bin/llama-server|$repo/bin/llama-server|' \
		scripts/flash-next-server.sh || die
}

src_configure() {
	# cmake.eclass blanks the RelWithDebInfo flags, so -DNDEBUG is lost
	# and plain assert() stays live, which upstream never ships.
	if ! use debug; then
		append-cflags "-DNDEBUG"
		append-cxxflags "-DNDEBUG"
	fi

	local mycmakeargs=(
		# Binaries share names with sci-misc/llama-cpp: keep the fork in
		# /opt and expose prefixed symlinks (see src_install). Shared
		# libraries, since static linking copies the CUDA kernels into
		# every binary.
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/opt/${PN}"
		-DBUILD_SHARED_LIBS=ON
		-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/opt/${PN}/lib"
		-DCMAKE_INSTALL_RPATH="${EPREFIX}/opt/${PN}/lib"
		-DCMAKE_SKIP_BUILD_RPATH=ON
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_EXAMPLES=OFF
		-DLLAMA_BUILD_SERVER=ON
		# The unified "llama" binary carries a self-updater that pipes a
		# remote script into sh.
		-DLLAMA_BUILD_APP=OFF
		# Both UI paths need the network (npm, or a Hugging Face bucket
		# keyed by mainline's build number). The API server works without.
		-DLLAMA_BUILD_UI=OFF
		-DLLAMA_USE_PREBUILT_UI=OFF
		-DLLAMA_OPENSSL=$(usex openssl)
		-DGGML_NATIVE=OFF	# don't set march
		-DGGML_CCACHE=OFF
		-DGGML_CUDA=$(usex cuda)
		-DGGML_CUDA_NCCL=OFF
		-DGGML_OPENMP=$(usex openmp)
		-DGGML_SSE42=$(usex cpu_flags_x86_sse4_2)
		-DGGML_AVX=$(usex cpu_flags_x86_avx)
		-DGGML_AVX_VNNI=$(usex cpu_flags_x86_avx_vnni)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2)
		-DGGML_BMI2=$(usex cpu_flags_x86_bmi2)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3)
		-DGGML_AVX512=$(usex cpu_flags_x86_avx512f)
		-DGGML_AVX512_VBMI=$(usex cpu_flags_x86_avx512vbmi)
		-DGGML_AVX512_VNNI=$(usex cpu_flags_x86_avx512_vnni)
		-DGGML_AVX512_BF16=$(usex cpu_flags_x86_avx512_bf16)
	)

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)/g++"
		# Upstream's quick start builds sm_86 only; CUDAARCHS from
		# make.conf wins, otherwise build for the local card.
		mycmakeargs+=( -DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS:-native}" )
		# nvcc recreates device symlinks during detection.
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# Nothing links against the fork: drop what would advertise /opt.
	rm -rf "${ED}/opt/${PN}/include" "${ED}/opt/${PN}/lib"/{cmake,pkgconfig} || die
	# The converters need numpy and gguf-py; sci-misc/llama-cpp has them.
	rm -f "${ED}/opt/${PN}/bin"/*.py || die

	local b n
	for b in "${ED}/opt/${PN}/bin"/*; do
		n=${b##*/}
		dosym -r "/opt/${PN}/bin/${n}" "/usr/bin/ampere-${n}"
	done

	# Flash-Next launcher and its expert profile; the script finds both
	# relative to its own location.
	exeinto /opt/${PN}/scripts
	doexe scripts/flash-next-server.sh
	insinto /opt/${PN}/data/moe
	doins data/moe/flash-next.env data/moe/flash-next-experts.strp \
		data/moe/flash-next.profile data/moe/flash-next.profile.json
	newbin - ampere-flash-next-server <<-EOF
		#!/bin/sh
		exec "${EPREFIX}/opt/${PN}/scripts/flash-next-server.sh" "\$@"
	EOF

	dodoc README.md QWEN_AMPERE.md data/moe/README.md
}

pkg_postinst() {
	elog "Binaries are in /opt/${PN}/bin, symlinked as ampere-llama-server,"
	elog "ampere-llama-bench and so on. Flash-Next starts with"
	elog "  FLASH_NEXT_DRAFTER=<drafter.gguf> ampere-flash-next-server -m <model.gguf>"
	elog "Set LLAMA_MOE_ARENA_OUTPUT_DIR to a disk with 16 GiB free, or long"
	elog "prompts keep their scratch output in RAM. Upstream tests RTX 30"
	elog "cards only; other generations run but are unmeasured."
}
