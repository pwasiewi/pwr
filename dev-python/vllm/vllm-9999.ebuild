# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
ROCM_VERSION=7.2

# USE=rust is not supported in the live ebuild: the CRATES vendor set is
# generated from a fixed rust/Cargo.lock and must be re-generated on every
# git HEAD bump.  The vllm-rs Rust frontend is opt-in at runtime via
# VLLM_USE_RUST_FRONTEND=1 (default off) and not load-bearing.

inherit distutils-r1 git-r3 rocm toolchain-funcs

EGIT_REPO_URI="https://github.com/vllm-project/vllm.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/${P}"

# flash-attention commit that vllm main pins in
# cmake/external_projects/vllm_flash_attn.cmake (GIT_TAG).  HARD-pinned here:
# SRC_URI is evaluated at parse time, so the fetched tarball, its Manifest
# entry and the FILESDIR patches must all match this exact commit.  We force
# vllm's CMake to use this tree via VLLM_FLASH_ATTN_SRC_DIR (src_configure),
# bypassing its own FetchContent GIT_TAG.  src_unpack only *warns* if vllm HEAD
# has since bumped the GIT_TAG — bump VLLM_FA_COMMIT (+ tarball, Manifest, the
# two -py314 / -fa3-only patches) when that happens.
VLLM_FA_COMMIT="2c839c33742309ec41e620bf837495ec9926c56e"

DESCRIPTION="High-throughput, memory-efficient inference and serving engine for LLMs (live)"
HOMEPAGE="
	https://github.com/vllm-project/vllm
	https://docs.vllm.ai/
"
SRC_URI="
	cuda? (
		https://github.com/vllm-project/flash-attention/archive/${VLLM_FA_COMMIT}.tar.gz
			-> vllm-flash-attn-${VLLM_FA_COMMIT:0:7}.gh.tar.gz
	)
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS=""
IUSE="cpu cuda humming rocm"
REQUIRED_USE="
	?? ( cpu cuda rocm )
	rocm? ( || ( ${ROCM_REQUIRED_USE} ) )
	humming? ( cuda )
"

# caffe2-9999 accepted via || alongside the stable floor.  The floor carries
# the MKL-scrub patch (r90) that prevents link-pollution from caffe2::mkl;
# caffe2-9999 from overlay pwr/stuff applies the same fix.
# pytorch/torchaudio/torchvision: >= floor so live pytorch-9999 satisfies.
# flashinfer/tilelang/humming-kernels keep ~ pins — they are tightly coupled
# to a specific vllm release and need manual bump on HEAD divergence.
RDEPEND="
	>=sci-ml/pytorch-2.11.0[${PYTHON_SINGLE_USEDEP}]
	sci-ml/caffe2[distributed,gloo]
	>=sci-ml/transformers-5.5.3[${PYTHON_SINGLE_USEDEP}]
	>=sci-ml/tokenizers-0.21.1[${PYTHON_SINGLE_USEDEP}]
	>=dev-python/xgrammar-0.2.0[${PYTHON_SINGLE_USEDEP}]
	<dev-python/xgrammar-1.0.0[${PYTHON_SINGLE_USEDEP}]
	>=dev-python/compressed-tensors-0.17.0[${PYTHON_SINGLE_USEDEP}]
	app-alternatives/ninja
	$(python_gen_cond_dep '
		dev-python/regex[${PYTHON_USEDEP}]
		dev-python/cachetools[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		sci-ml/sentencepiece[${PYTHON_USEDEP}]
		>=sci-ml/safetensors-0.6.2[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		>=dev-python/requests-2.26.0[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		dev-python/blake3[${PYTHON_USEDEP}]
		dev-python/py-cpuinfo[${PYTHON_USEDEP}]
		>=dev-python/protobuf-5.29.6[${PYTHON_USEDEP}]
		>=dev-python/fastapi-0.115.0[${PYTHON_USEDEP}]
		>=dev-python/aiohttp-3.13.3[${PYTHON_USEDEP}]
		>=dev-python/openai-2.0.0[${PYTHON_USEDEP}]
		>=dev-python/pydantic-2.12.0[${PYTHON_USEDEP}]
		>=dev-python/prometheus-client-0.18.0[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		>=dev-python/prometheus-fastapi-instrumentator-7.0.0[${PYTHON_USEDEP}]
		>=dev-python/tiktoken-0.6.0[${PYTHON_USEDEP}]
		>=dev-python/lm-format-enforcer-0.11.3[${PYTHON_USEDEP}]
		>=dev-python/llguidance-1.7.0[${PYTHON_USEDEP}]
		>=dev-python/outlines-core-0.2.14[${PYTHON_USEDEP}]
		>=dev-python/diskcache-5.6.3[${PYTHON_USEDEP}]
		>=dev-python/lark-1.2.2[${PYTHON_USEDEP}]
		>=dev-python/typing-extensions-4.10[${PYTHON_USEDEP}]
		>=dev-python/filelock-3.16.1[${PYTHON_USEDEP}]
		dev-python/partial-json-parser[${PYTHON_USEDEP}]
		>=dev-python/pyzmq-25.0.0[${PYTHON_USEDEP}]
		dev-python/msgspec[${PYTHON_USEDEP}]
		>=dev-python/gguf-0.17.0[${PYTHON_USEDEP}]
		>=dev-python/mistral-common-1.11.3[${PYTHON_USEDEP},image]
		>=media-libs/opencv-4.12.0[python,${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/six[${PYTHON_USEDEP}]
		dev-python/einops[${PYTHON_USEDEP}]
		>=dev-python/depyf-0.20.0[${PYTHON_USEDEP}]
		dev-python/cloudpickle[${PYTHON_USEDEP}]
		dev-python/uvloop[${PYTHON_USEDEP}]
		dev-python/watchfiles[${PYTHON_USEDEP}]
		dev-python/python-json-logger[${PYTHON_USEDEP}]
		dev-python/pybase64[${PYTHON_USEDEP}]
		dev-python/cbor2[${PYTHON_USEDEP}]
		dev-python/ijson[${PYTHON_USEDEP}]
		dev-python/setproctitle[${PYTHON_USEDEP}]
		>=dev-python/openai-harmony-0.0.3[${PYTHON_USEDEP}]
		>=dev-python/anthropic-0.71.0[${PYTHON_USEDEP}]
		>=dev-python/model-hosting-container-standards-0.1.14[${PYTHON_USEDEP}]
		<dev-python/model-hosting-container-standards-1.0.0[${PYTHON_USEDEP}]
		dev-python/mcp[${PYTHON_USEDEP}]
		>=dev-python/opentelemetry-sdk-1.27.0[${PYTHON_USEDEP}]
		>=dev-python/opentelemetry-api-1.27.0[${PYTHON_USEDEP}]
		>=dev-python/opentelemetry-exporter-otlp-1.27.0[${PYTHON_USEDEP}]
		>=dev-python/opentelemetry-semantic-conventions-ai-0.4.1[${PYTHON_USEDEP}]
	')
	cpu? (
		|| ( >=sci-ml/caffe2-2.11.0-r90 ~sci-ml/caffe2-9999 )
		>=sci-ml/torchaudio-2.11.0
		$(python_gen_cond_dep '
			>=dev-python/numba-0.65.0[${PYTHON_USEDEP}]
		')
	)
	cuda? (
		|| ( >=sci-ml/caffe2-2.11.0-r90 ~sci-ml/caffe2-9999 )
		>=sci-ml/torchaudio-2.11.0
		>=sci-ml/torchvision-0.26.0[${PYTHON_SINGLE_USEDEP}]
		~dev-python/flashinfer-python-0.6.12[${PYTHON_SINGLE_USEDEP}]
		~dev-python/tilelang-0.1.9[${PYTHON_SINGLE_USEDEP}]
		>=dev-python/quack-kernels-0.3.3[${PYTHON_SINGLE_USEDEP}]
		humming? ( ~dev-python/humming-kernels-0.1.4[${PYTHON_SINGLE_USEDEP}] )
		$(python_gen_cond_dep '
			>=dev-python/numba-0.65.0[${PYTHON_USEDEP}]
			>=dev-python/fastsafetensors-0.3.2[${PYTHON_USEDEP}]
			~dev-python/nvidia-cutlass-dsl-4.5.2[${PYTHON_USEDEP}]
			~dev-python/triton-bin-3.6.0[${PYTHON_USEDEP}]
		')
		dev-util/nvidia-cuda-toolkit:=
	)
	rocm? (
		|| ( >=sci-ml/caffe2-2.11.0-r90 ~sci-ml/caffe2-9999 )
		>=sci-ml/torchaudio-2.11.0
		>=sci-ml/torchvision-0.26.0[${PYTHON_SINGLE_USEDEP}]
		>=dev-python/runai-model-streamer-bin-0.15.7[${PYTHON_SINGLE_USEDEP}]
		~dev-python/tensorizer-2.10.1[${PYTHON_SINGLE_USEDEP}]
		~dev-python/tilelang-0.1.10[${PYTHON_SINGLE_USEDEP}]
		$(python_gen_cond_dep '
			>=dev-python/numba-0.65.0[${PYTHON_USEDEP}]
			~dev-python/conch-triton-kernels-1.2.1[${PYTHON_USEDEP}]
			~dev-python/triton-bin-3.6.0[${PYTHON_USEDEP}]
			>=dev-util/amdsmi-7.0.2[${PYTHON_USEDEP}]
		')
		>=dev-util/hip-7.2:=
		>=sci-libs/hipBLAS-7.2:=
		>=sci-libs/hipBLASLt-7.2:=
		>=sci-libs/hipFFT-7.2:=
		>=sci-libs/hipRAND-7.2:=
		>=sci-libs/hipSOLVER-7.2:=
		>=sci-libs/hipSPARSE-7.2:=
		>=sci-libs/hipCUB-7.2:=
	)
"
BDEPEND="
	>=dev-build/cmake-3.26.1
	app-alternatives/ninja
	>=sci-ml/pytorch-2.11.0[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		>=dev-python/setuptools-77.0.3[${PYTHON_USEDEP}]
		>=dev-python/setuptools-scm-8.0[${PYTHON_USEDEP}]
		>=dev-python/setuptools-rust-1.9.0[${PYTHON_USEDEP}]
		>=dev-python/packaging-24.2[${PYTHON_USEDEP}]
		dev-python/jinja2[${PYTHON_USEDEP}]
	')
	cuda? (
		dev-util/nvidia-cuda-toolkit:=
	)
	rocm? (
		>=dev-util/hip-7.2:=
		>=dev-util/hipcc-7.2:=
	)
"

RESTRICT="
	test
	cpu? ( network-sandbox )
	cuda? ( network-sandbox )
	rocm? ( network-sandbox )
"

# Pretend a version so setuptools-scm doesn't abort on the live checkout.
export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}

src_unpack() {
	git-r3_src_unpack

	if use cuda; then
		# Maintenance check only: warn (do NOT override) if vllm HEAD has bumped
		# the flash-attn GIT_TAG past our hard pin.  Overriding VLLM_FA_COMMIT
		# here would desync from the parse-time SRC_URI fetch + Manifest + the
		# commit-named patches, which is exactly the failure this replaced.
		local fa_cmake="${EGIT_CHECKOUT_DIR}/cmake/external_projects/vllm_flash_attn.cmake"
		if [[ -f ${fa_cmake} ]]; then
			local fa_commit_live
			fa_commit_live=$(grep 'GIT_TAG' "${fa_cmake}" | grep -oE '[0-9a-f]{40}' | head -n 1)
			if [[ -n ${fa_commit_live} && ${fa_commit_live} != "${VLLM_FA_COMMIT}" ]]; then
				ewarn "vllm main now pins flash-attn ${fa_commit_live:0:7}, ebuild has ${VLLM_FA_COMMIT:0:7}."
				ewarn "Bump VLLM_FA_COMMIT (+ tarball, Manifest, -py314/-fa3-only patches) to match."
				ewarn "Building against the pinned ${VLLM_FA_COMMIT:0:7} via VLLM_FLASH_ATTN_SRC_DIR."
			fi
		fi

		# The pinned tarball is pre-fetched by SRC_URI; unpack it so
		# VLLM_FLASH_ATTN_SRC_DIR (src_configure) can point CMake at it and skip
		# its network FetchContent.
		local fa_tarball="${DISTDIR}/vllm-flash-attn-${VLLM_FA_COMMIT:0:7}.gh.tar.gz"
		[[ -f ${fa_tarball} ]] && unpack "${fa_tarball}"
	fi
}

src_prepare() {
	distutils-r1_src_prepare

	# fused single-tensor PEFT adapters on packed modules (unsloth GRPO)
	eapply "${FILESDIR}/vllm-9999-lora-fused-packed-module.patch"
	# stacked q/k/v name mapping collapses per-module LoRA entries
	eapply "${FILESDIR}/vllm-9999-lora-no-stacked-name-mapping.patch"

	# vllm's setup.py unconditionally wires the vllm-rs RustExtension.
	# The live ebuild does not support USE=rust (crate vendor set not maintained).
	grep -q 'rust_extensions=rust_extensions,' setup.py ||
		die "vllm-rs RustExtension wiring changed; revisit the rust gate"
	sed -i 's/rust_extensions=rust_extensions,/rust_extensions=[],/' \
		setup.py || die

	if use cuda; then
		local fa_dir="${WORKDIR}/flash-attention-${VLLM_FA_COMMIT}"
		if [[ -d ${fa_dir} ]]; then
			pushd "${fa_dir}" >/dev/null || die
			# Skip FA3 (Hopper) target when no Hopper arch in CUDA_ARCHS.
			# Patch filename uses 7-char commit prefix — fall back gracefully if
			# a new FA commit has no matching patch yet (builds will still work,
			# just compile FA3 for all arches which wastes time on non-Hopper).
			local fa3_patch="${FILESDIR}/vllm-flash-attn-${VLLM_FA_COMMIT:0:7}-fa3-only-when-archs.patch"
			local py314_patch="${FILESDIR}/vllm-flash-attn-${VLLM_FA_COMMIT:0:7}-py314.patch"
			if [[ -f ${fa3_patch} ]]; then
				eapply -p0 "${fa3_patch}"
			else
				ewarn "No fa3-only-when-archs patch for flash-attn ${VLLM_FA_COMMIT:0:7};"
				ewarn "FA3 kernels will compile for all archs (slower on non-Hopper)."
			fi
			if [[ -f ${py314_patch} ]]; then
				eapply -p0 "${py314_patch}"
			fi
			popd >/dev/null || die
		fi
	fi
}

src_configure() {
	# vllm's setup.py auto-adds ccache/sccache as the C/C++/CUDA compiler
	# launcher when either is on PATH, so nvcc kernel objects get cached too.
	# The bottleneck is persistence: a full CUDA build misses ~40G, which the
	# 5G ccache default evicts, so every rebuild stays cold (~40 min). Enable
	# a persistent, portage-writable cache with FEATURES="ccache" (make.conf or
	# /etc/portage/package.env -> gives CCACHE_DIR=/var/cache/ccache). When it
	# is active, size the cache and relax nvcc-hostile checks so hits land on
	# HEAD bumps and Python-only patches. Defaults only; env-file wins.
	if [[ ${FEATURES} == *ccache* ]] && type -P ccache >/dev/null; then
		: "${CCACHE_MAXSIZE:=60G}"
		: "${CCACHE_SLOPPINESS:=locale,time_macros,include_file_ctime,include_file_mtime}"
		export CCACHE_MAXSIZE CCACHE_SLOPPINESS
		einfo "ccache active: CCACHE_DIR=${CCACHE_DIR:-<portage default>} MAXSIZE=${CCACHE_MAXSIZE}"
	fi

	if use cuda; then
		export VLLM_TARGET_DEVICE=cuda
		local fa_dir="${WORKDIR}/flash-attention-${VLLM_FA_COMMIT}"
		[[ -d ${fa_dir} ]] && export VLLM_FLASH_ATTN_SRC_DIR="${fa_dir}"
		export CUDAHOSTCXX=/usr/bin/x86_64-pc-linux-gnu-g++-15
		export CMAKE_ARGS+=" -DCMAKE_CUDA_HOST_COMPILER=${CUDAHOSTCXX}"
		export MAX_JOBS="${MAX_JOBS:-4}"
		export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-${MAX_JOBS}}"
	elif use cpu; then
		export VLLM_TARGET_DEVICE=cpu
		local gomp_dir
		gomp_dir=$(dirname "$($(tc-getCC) -print-file-name=libgomp.so)")
		export CMAKE_ARGS+=" -DCMAKE_LIBRARY_PATH=${gomp_dir}"
	elif use rocm; then
		export VLLM_TARGET_DEVICE=rocm
		export PYTORCH_ROCM_ARCH=$(get_amdgpu_flags)
		export MAX_JOBS="${MAX_JOBS:-4}"
		export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-${MAX_JOBS}}"
	else
		export VLLM_TARGET_DEVICE=empty
	fi
	distutils-r1_src_configure
}

pkg_postinst() {
	if use cuda; then
		elog "vllm's CUDA path pulls dev-python/flashinfer-python, which"
		elog "JIT-compiles GPU kernels with nvcc on first inference. CUDA"
		elog "13.x nvcc rejects host compilers newer than gcc 15:"
		elog ""
		elog "  NVCC_PREPEND_FLAGS=\"-ccbin /usr/bin/${CHOST}-g++-15\" vllm serve ..."
		elog ""
		elog "Flash-attention commit used: ${VLLM_FA_COMMIT:0:7}"
		elog "If vllm HEAD changed the GIT_TAG, re-run: ebuild ... fetch"
	fi

	if use cuda && ! use humming; then
		elog ""
		elog "The optional 'humming' MXFP4 quantization backend is off."
		elog "Enable USE=humming to pull dev-python/humming-kernels."
	fi

	if use rocm; then
		elog "Launch vllm with USE_LIBUV=0 to avoid TCPStore libuv errors:"
		elog "  USE_LIBUV=0 vllm serve ..."
	fi

	elog ""
	elog "This is a live (9999) ebuild tracking vllm main."
	elog "flashinfer/tilelang/humming-kernels pins may lag behind HEAD."

	if use cuda && [[ ${FEATURES} != *ccache* ]]; then
		elog ""
		elog "The CUDA build takes ~40 min with no compiler cache. Enable a"
		elog "persistent ccache to cut rebuilds to minutes on a warm cache:"
		elog "  install -d -o portage -g portage /var/cache/ccache"
		elog "  echo 'dev-python/vllm ccache.conf' >> /etc/portage/package.env"
		elog "  # /etc/portage/env/ccache.conf: FEATURES=\"ccache\";"
		elog "  #   CCACHE_DIR=\"/var/cache/ccache\"; CCACHE_MAXSIZE=\"60G\""
		elog "vllm's setup.py auto-wires ccache as the CUDA compiler launcher."
	fi
}
