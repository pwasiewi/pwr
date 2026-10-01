# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit cmake cuda optfeature python-single-r1

DESCRIPTION="CUDA inference engine for Qwen3.8-Flash-Next with a per-expert VRAM cache"
HOMEPAGE="https://github.com/Niko1221/Strata"
# The engine builds ggml's CPU library and a few ggml-cuda MMQ kernels from
# llama.cpp at the commit its CMakeLists pins (FetchContent); shipped here as
# a second distfile and handed over with STRATA_GGML_DIR.
LLAMA_COMMIT="3cf03257f219afbe7334045ff7c6a06ac68c627d"
SRC_URI="
	https://github.com/Niko1221/Strata/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/ggml-org/llama.cpp/archive/${LLAMA_COMMIT}.tar.gz
		-> llama.cpp-${LLAMA_COMMIT}.tar.gz
"
S="${WORKDIR}/Strata-${PV}"

# MIT: engine, third_party/ggml headers and the bundled llama.cpp/ggml; OFL-1.1: the web UI font.
# data/experimental-speed-projection (Qwen Community License 1.0) is not installed.
LICENSE="MIT OFL-1.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cpu_flags_x86_avx cpu_flags_x86_avx2 cpu_flags_x86_avx512f cpu_flags_x86_f16c cpu_flags_x86_fma3"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
# The test suite fetches Catch2 with FetchContent at configure time (network);
# the parity tests additionally need a llama.cpp build tree.
RESTRICT="test"

DEPEND="dev-util/nvidia-cuda-toolkit:="
RDEPEND="
	${DEPEND}
	${PYTHON_DEPS}
	x11-drivers/nvidia-drivers
	$(python_gen_cond_dep '
		dev-python/jinja2[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/regex[${PYTHON_USEDEP}]
	')
"

src_prepare() {
	cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DSTRATA_ENABLE_CUDA=ON
		-DSTRATA_ENABLE_HIP=OFF
		-DSTRATA_BUILD_TESTS=OFF
		-DSTRATA_PORTABLE=OFF
		-DSTRATA_WERROR=OFF
		# upstream defaults to 120; CUDAARCHS from make.conf wins
		-DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS:-120}"
		# ggml from the bundled llama.cpp tree instead of a git clone
		-DSTRATA_GGML_DIR="${WORKDIR}/llama.cpp-${LLAMA_COMMIT}"
		-DGGML_CCACHE=OFF	# Portage's FEATURES decide ccache
		-DGGML_NATIVE=OFF	# no -march=native; CFLAGS and the flags below
		-DGGML_AVX=$(usex cpu_flags_x86_avx)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2)
		-DGGML_AVX512=$(usex cpu_flags_x86_avx512f)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3)
		-DGGML_OPENMP=OFF
		-DGGML_BUILD_TESTS=OFF
		-DGGML_BUILD_EXAMPLES=OFF
	)
	local -x CUDAHOSTCXX="$(cuda_gccdir)"
	cuda_add_sandbox
	addpredict "/dev/char/"
	cmake_src_configure
}

src_compile() {
	# upstream has no install() rules and builds ~40 parity/diagnostic tools;
	# only the engine and the GGUF inspection tools are installed
	cmake_src_compile strata strata-gguf strata-dequant strata-plan
}

src_install() {
	local dir=/opt/${PN}

	exeinto "${dir}/bin"
	local b
	for b in strata strata-gguf strata-dequant strata-plan; do
		doexe "${BUILD_DIR}/${b}"
	done

	# serve/server.py and tools/*.py locate their siblings relative to the
	# tree root, so the upstream layout is kept under /opt/strata
	insinto "${dir}"
	doins -r serve tools chat.py
	insinto "${dir}/data"
	doins data/*.bin
	python_optimize "${ED}${dir}"

	# tools/_paths.py wants the directory that CONTAINS the gguf package
	newbin - strata-serve <<-EOT
		#!/bin/sh
		export STRATA_GGUF_PY="\${STRATA_GGUF_PY:-$(python_get_sitedir)}"
		exec ${EPYTHON} "${EPREFIX}${dir}/serve/server.py" "\$@"
	EOT
	newbin - strata-tool <<-EOT
		#!/bin/sh
		# usage: strata-tool <name> [args] -> runs ${dir}/tools/<name>.py
		export STRATA_GGUF_PY="\${STRATA_GGUF_PY:-$(python_get_sitedir)}"
		t="\$1"; shift
		exec ${EPYTHON} "${EPREFIX}${dir}/tools/\${t%.py}.py" "\$@"
	EOT

	dodoc README.md
	docinto docs
	dodoc -r docs/.
}

pkg_postinst() {
	optfeature "the MTP pack tool (strata-tool mtp_rt), which imports llama.cpp's gguf-py" dev-python/gguf
	elog "Strata serves one model family (Qwen3.8-Flash-Next / qwen4exp) and needs a"
	elog "prepared pack plus the MTP draft (tools iq_pack, mtp_fetch, mtp_pack, mtp_rt;"
	elog "run them with 'strata-tool <name>'). The server takes a JSON config whose \"exe\""
	elog "is ${EPREFIX}/opt/${PN}/bin/strata and whose args point at the pack, the GGUF"
	elog "shards and ${EPREFIX}/opt/${PN}/data/expert-profile.bin; it writes its"
	elog "shared-settings file next to that config. Start: strata-serve --engine strata"
	elog "--config <file> --port 8080. It holds ~39 GB RAM for the IQ2_XS model: do not"
	elog "run heavy jobs beside it."
}
