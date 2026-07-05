# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake cuda git-r3

DESCRIPTION="llama.cpp fork with SOTA quants and fast CPU/GPU hybrid MoE inference"
HOMEPAGE="https://github.com/ikawrakow/ik_llama.cpp"
EGIT_REPO_URI="https://github.com/ikawrakow/ik_llama.cpp.git"
EGIT_BRANCH="main"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

# Fork diverged from mainline llama.cpp in 2024: no GGML_SSE42/GGML_BMI2
# options, HIP backend is still GGML_HIPBLAS, GGML_NCCL defaults to ON.
CPU_FLAGS_X86=( avx avx2 avx512f avx512vbmi f16c fma3 )

IUSE="+cuda +curl +openmp vulkan"
IUSE+=" ${CPU_FLAGS_X86[@]/#/cpu_flags_x86_}"

CDEPEND="
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
	curl? ( net-misc/curl:= )
	openmp? ( llvm-runtimes/openmp:= )
"
DEPEND="${CDEPEND}
	vulkan? (
		dev-util/spirv-headers
		dev-util/vulkan-headers
	)
"
RDEPEND="${CDEPEND}
	vulkan? ( media-libs/vulkan-loader )
"
BDEPEND="vulkan? ( media-libs/shaderc )"

src_prepare() {
	use cuda && cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		# binaries share names with sci-misc/llama-cpp — keep the fork
		# in /opt and expose ik- prefixed symlinks (see src_install);
		# shared libs + rpath, since static linking duplicates the CUDA
		# kernels into every binary (~10 GiB installed)
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/opt/${PN}"
		-DBUILD_SHARED_LIBS=ON
		-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/opt/${PN}/lib"
		-DCMAKE_INSTALL_RPATH="${EPREFIX}/opt/${PN}/lib"
		-DCMAKE_SKIP_BUILD_RPATH=ON
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_EXAMPLES=ON
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_CURL=$(usex curl)
		-DGGML_NATIVE=OFF	# don't set march
		-DGGML_CCACHE=OFF
		-DGGML_CUDA=$(usex cuda)
		-DGGML_NCCL=OFF
		-DGGML_OPENMP=$(usex openmp)
		-DGGML_VULKAN=$(usex vulkan)
		-DGGML_AVX=$(usex cpu_flags_x86_avx)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3)
		-DGGML_AVX512=$(usex cpu_flags_x86_avx512f)
		-DGGML_AVX512_VBMI=$(usex cpu_flags_x86_avx512vbmi)
	)

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		# fork's default CMAKE_CUDA_ARCHITECTURES predates Blackwell;
		# CUDAARCHS from make.conf wins, otherwise build for local GPU
		mycmakeargs+=( -DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS:-native}" )
		# tries to recreate dev symlinks
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# drop headers, cmake and pkg-config files so nothing advertises
	# the /opt prefix to consumers; the .so stay (rpath-linked)
	rm -rf "${ED}/opt/${PN}/include" "${ED}/opt/${PN}/lib"/{cmake,pkgconfig} || die

	# convert*.py needs numpy; mainline sci-misc/llama-cpp ships converters
	rm -f "${ED}/opt/${PN}/bin"/*.py

	local b n
	for b in "${ED}/opt/${PN}/bin"/*; do
		n=${b##*/}
		dosym -r "/opt/${PN}/bin/${n}" "/usr/bin/ik-${n}"
	done

	dodoc README.md
}

pkg_postinst() {
	elog "Binaries are installed in /opt/${PN}/bin and symlinked with an"
	elog "ik- prefix, e.g. ik-llama-server, ik-llama-cli, ik-llama-bench."
	elog "Benchmark flag changes with ik-llama-sweep-bench before adopting"
	elog "them. For hybrid MoE offload avoid -rtr with experts on CPU."
}
