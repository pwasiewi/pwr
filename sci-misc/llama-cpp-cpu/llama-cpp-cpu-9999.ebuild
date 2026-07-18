# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="llama.cpp built CPU-only (no CUDA/ROCm/Vulkan/OpenCL/SYCL context overhead)"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"
EGIT_REPO_URI="https://github.com/ggml-org/llama.cpp.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

# Same upstream as sci-misc/llama-cpp, deliberately CPU-only: a CUDA-built
# llama-server still opens a CUDA context (cuBLAS/cuBLASLt handles + compute
# staging buffers) even when run with -ngl 0, costing ~358 MiB VRAM per
# process regardless of model size (measured on two always -ngl 0 servers:
# aillama's embed-start and rerank-start). This variant removes GPU backends
# entirely so those two servers cost zero VRAM. CPU math acceleration
# (openblas/blis/flexiblas/openmp) stays available same as upstream.
CPU_FLAGS_X86=( avx avx2 avx512f avx512vbmi bmi2 f16c fma3 sse4_2 )

IUSE="openblas +openmp blis +openssl flexiblas examples"
IUSE+=" ${CPU_FLAGS_X86[@]/#/cpu_flags_x86_}"

REQUIRED_USE="
	?? (
		openblas
		blis
		flexiblas
	)
"

CDEPEND="
	openblas? ( sci-libs/openblas:= )
	openmp? ( llvm-runtimes/openmp:= )
	blis? ( sci-libs/blis:= )
	flexiblas? ( sci-libs/flexiblas:= )
	openssl? ( dev-libs/openssl:= )
"
RDEPEND="${CDEPEND}"
DEPEND="${CDEPEND}"

src_configure() {
	local mycmakeargs=(
		# own /opt prefix + shared libs (rpath) so this coexists with
		# sci-misc/llama-cpp without touching /usr/bin except for the one
		# explicit symlink added in src_install
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/opt/${PN}"
		-DBUILD_SHARED_LIBS=ON
		-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/opt/${PN}/lib"
		-DCMAKE_INSTALL_RPATH="${EPREFIX}/opt/${PN}/lib"
		-DCMAKE_SKIP_BUILD_RPATH=ON
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_EXAMPLES=$(usex examples)
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_UI=OFF
		-DLLAMA_BUILD_WEBUI=OFF
		-DLLAMA_OPENSSL=$(usex openssl)
		-DGENTOO_REMOVE_CMAKE_BLAS_HACK=ON
		-DGGML_NATIVE=0
		-DGGML_RPC=OFF
		# hard off: this variant exists specifically to avoid GPU backend
		# context init (see DESCRIPTION comment above) — no IUSE, no toggle
		-DGGML_CUDA=OFF
		-DGGML_HIP=OFF
		-DGGML_VULKAN=OFF
		-DGGML_OPENCL=OFF
		-DGGML_SYCL=OFF
		-DGGML_OPENMP=$(usex openmp)
	)

	mycmakeargs+=(
		-DGGML_SSE42=$(usex cpu_flags_x86_sse4_2)
		-DGGML_AVX=$(usex cpu_flags_x86_avx)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2)
		-DGGML_BMI2=$(usex cpu_flags_x86_bmi2)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3)
		-DGGML_AVX512=$(usex cpu_flags_x86_avx512f)
		-DGGML_AVX512_VBMI=$(usex cpu_flags_x86_avx512vbmi)
	)

	if use openblas; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS )
	fi
	if use blis; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FLAME )
	fi
	if use flexiblas; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FlexiBLAS )
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# headless CPU variant: no cmake/pkgconfig/headers advertised, no
	# converter scripts (mainline sci-misc/llama-cpp already ships those)
	rm -rf "${ED}/opt/${PN}/include" "${ED}/opt/${PN}/lib"/{cmake,pkgconfig} || die
	rm -f "${ED}/opt/${PN}/bin"/*.py

	# Only llama-server is wired system-wide, renamed llama-cpu, so it
	# can never collide with /usr/bin/llama-server from the CUDA build
	# (sci-misc/llama-cpp) even if both packages are installed at once.
	# Other tools (llama-cli, llama-bench, ...) stay under /opt/${PN}/bin
	# unlinked — this variant's only consumer (aillama embed/rerank) never
	# needs them, and skipping the symlinks avoids having to prefix every
	# single one just to dodge a collision that doesn't otherwise exist.
	dosym -r "/opt/${PN}/bin/llama-server" "/usr/bin/llama-cpu"

	dodoc README.md
}

src_test() {
	"${BUILD_DIR}"/bin/llama-server --help > /dev/null || die "llama-server --help failed"
}

pkg_postinst() {
	elog "CPU-only llama-server installed as /usr/bin/llama-cpu"
	elog "(no CUDA/ROCm/Vulkan/OpenCL/SYCL — zero VRAM context overhead)."
	elog "Other tools (llama-cli, llama-bench, ...) are in /opt/${PN}/bin"
	elog "but not symlinked into /usr/bin."
}
