# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Live TensorFlow built from source with the host toolchain (2026-10-20, user request).
# ::gentoo treecleaned sci-libs/tensorflow and dev-build/bazel in 2024; upstream ships cp314 only as
# 2.22.0rc0 / tf-nightly wheels. This ebuild builds the wheel with Bazel (via bazelisk), then installs
# it into the system Python. Research: ~/Claude/llm/research/tensorflow-py314-20261020.md
#
# What comes from the host and what does not:
#  - C/C++ compiler: the system clang 22 (`--config=clang_local`, hermetic CC toolchain OFF).
#  - CUDA (USE=cuda): the system toolkit in /opt/cuda (13.x) and cuDNN, via LOCAL_CUDA_PATH /
#    LOCAL_CUDNN_PATH; compiled for sm_120 + compute_120 only. NCCL stays hermetic (not installed here).
#  - Libraries: TF_SYSTEM_LIBS for the version-tolerant C ones (png, gif, jpeg, snappy, sqlite, curl,
#    jsoncpp; zlib is wanted as zlib-ng by the vendored LLVM, so it stays bundled). protobuf, grpc, abseil, re2, boringssl, pybind11, flatbuffers and the Python
#    archives stay bundled: TF pins them tightly, and the Python ones no longer support a system copy.
#  - Python: Bazel's hermetic interpreter pinned to the system minor (3.14) so the wheel is cp314;
#    the wheel is installed into the system site-packages and runs on system numpy/protobuf/h5py.
#
# Bazel needs the network (bazelisk downloads Bazel 7.7.0, the repo rules fetch pinned sources and
# the requirements lock), hence RESTRICT=network-sandbox. Output root and disk cache live outside
# WORKDIR (TF_BAZEL_CACHE, default /var/cache/bazel-tf) so a failed build resumes, not restarts.
# Expect hours and 20-40 GB RAM; MAKEOPTS -j caps Bazel jobs.

PYTHON_COMPAT=( python3_14 )

inherit check-reqs git-r3 multiprocessing python-single-r1

DESCRIPTION="Computation framework using data flow graphs (live, built from source)"
HOMEPAGE="https://www.tensorflow.org/ https://github.com/tensorflow/tensorflow"
EGIT_REPO_URI="https://github.com/tensorflow/tensorflow.git"
# Pin a known commit for a reproducible attempt: EGIT_OVERRIDE_COMMIT_TENSORFLOW_TENSORFLOW=<sha>

LICENSE="Apache-2.0 cuda? ( NVIDIA-CUDA )"
SLOT="0"
IUSE="cuda"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="network-sandbox strip test cuda? ( bindist )"
PROPERTIES="live"

# Only archives whose tf_http_archive still declares a system_build_file (master, 2026-10-21): the Python
# packages (absl_py, six, wrapt, ...) lost theirs although syslibs_configure.bzl still lists them, and naming
# one makes the repository rule create nothing ("_tf_http_archive rule //external:absl_py must create a
# directory"). pybind11, re2, grpc, boringssl, protobuf, flatbuffers stay bundled: TF pins their versions.
# zlib stays bundled too: the vendored llvm-project asks for @zlib//:zlib-ng, which systemlibs/zlib.BUILD
# does not define (attempt 3, 2026-10-21). The seven below are consumed only by TF's own targets.
TF_SYSLIBS=(
	curl gif jsoncpp_git libjpeg_turbo org_sqlite png snappy
)

COMMON_DEPEND="
	app-arch/snappy:=
	dev-db/sqlite:3
	dev-libs/jsoncpp:=
	media-libs/giflib:=
	media-libs/libjpeg-turbo:=
	media-libs/libpng:=
	net-misc/curl
	cuda? (
		dev-libs/cudnn
		>=dev-util/nvidia-cuda-toolkit-13
	)
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="
	${COMMON_DEPEND}
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		>=dev-python/absl-py-1.0.0[${PYTHON_USEDEP}]
		>=dev-python/astunparse-1.6.0[${PYTHON_USEDEP}]
		>=dev-python/flatbuffers-25.9.23[${PYTHON_USEDEP}]
		>=dev-python/gast-0.2.1[${PYTHON_USEDEP}]
		>=dev-python/google-pasta-0.1.1[${PYTHON_USEDEP}]
		>=dev-python/grpcio-1.24.3[${PYTHON_USEDEP}]
		dev-python/h5py[${PYTHON_USEDEP}]
		>=dev-python/ml-dtypes-0.5.1[${PYTHON_USEDEP}]
		>=dev-python/numpy-1.26.0[${PYTHON_USEDEP}]
		>=dev-python/opt-einsum-2.3.2[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		<dev-python/protobuf-8[${PYTHON_USEDEP}]
		>=dev-python/requests-2.21.0[${PYTHON_USEDEP}]
		>=dev-python/six-1.12.0[${PYTHON_USEDEP}]
		>=dev-python/termcolor-1.1.0[${PYTHON_USEDEP}]
		>=dev-python/typing-extensions-3.6.6[${PYTHON_USEDEP}]
		>=dev-python/wrapt-1.11.0[${PYTHON_USEDEP}]
		sci-ml/keras[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	${PYTHON_DEPS}
	dev-build/bazelisk[bazel-symlink]
	dev-lang/nasm
	dev-vcs/git
	llvm-core/clang:22
	llvm-core/lld:22
	$(python_gen_cond_dep '
		dev-python/installer[${PYTHON_USEDEP}]
	')
"

TF_BAZEL_CACHE="${TF_BAZEL_CACHE:-/var/cache/bazel-tf}"

# clang 22 + libstdc++ 16: XLA's __device__ constexpr bf16/half infinity constants go through the constexpr but
# unannotated absl::bit_cast, which instantiates std::is_trivially_copyable in a device constant-evaluation
# context where libstdc++ 16's host-only __and_fn is "not viable" (GPU attempt 6). __builtin_bit_cast does
# the same check inside the compiler. Reproduced and verified with clang++ -x cuda; XLA main is unchanged.
PATCHES=( "${FILESDIR}/${P}-xla-bf16-infinity-builtin-bit-cast.patch" )

src_prepare() {
	default   # applies PATCHES to the live checkout
}

pkg_pretend() {
	CHECKREQS_MEMORY="24G"
	CHECKREQS_DISK_BUILD="40G"
	check-reqs_pkg_pretend
}

pkg_setup() {
	CHECKREQS_MEMORY="24G"
	CHECKREQS_DISK_BUILD="40G"
	check-reqs_pkg_setup
	python-single-r1_pkg_setup
	# Persistent Bazel state, owned by the build user, survives failed attempts.
	install -d -m 0755 -o portage -g portage "${TF_BAZEL_CACHE}"{,/output_user_root,/disk_cache,/bazelisk} \
		|| die "cannot create ${TF_BAZEL_CACHE}"
}

src_configure() {
	local clang_bin=/usr/lib/llvm/22/bin
	# Force-included headers must live under a toolchain "builtin include directory", or Bazel's absolute
	# path inclusion check fails every compile that pulls them in (GPU attempt 5). The autoconfiguration
	# derives that list from a `clang -E -v` probe run with BAZEL_CXXOPTS, so -isystem${T}/cuda-shim there
	# registers the directory (${T} is a stable path across emerges). A -isystem cannot break the probes
	# the way -include did. Cost: toolchain flags are part of every action key, so the disk cache misses once.
	mkdir -p "${T}/cuda-shim" || die
	[[ -x ${clang_bin}/clang ]] || die "clang 22 not found in ${clang_bin}"

	# highway cannot compile its 512-bit code paths with clang 22: the intrinsics' always_inline target
	# attribute no longer matches the pragma-pushed functions ("_mm512_set1_epi8 requires target feature
	# 'avx512f', but would be inlined into function 'Set'"; google/highway#2705, Gentoo bug 916752). The
	# effective copy is TF's own com_google_highway() = 1.3.0 (registered as @highway BEFORE XLA's 1.4.0 pin),
	# which still treats AVX10.2 as attainable on clang 22, so that target must be masked too (attempt 7).
	# Every 512-bit target is disabled below; this host (znver3) has no AVX-512 anyway. Reproduced and
	# verified locally with `clang++ -c` (codegen; -fsyntax-only never shows these errors).
	# The pinned BoringSSL builds with -Werror and predates glibc 2.44's const-generic memchr (__glibc_const_generic):
	# internal.h "returning 'const void *' from a function with result type 'void *' discards qualifiers".
	# -includecstdint: the pinned tf_runtime and friends use int64_t without including <cstdint>; GCC 16's
	# libstdc++ (clang 22's default stdlib here) no longer provides it transitively ("forward_decls.h:110:
	# unknown type name 'int64_t'", attempt 8). It must NOT go into BAZEL_CXXOPTS: cc_configure runs several
	# `clang -E -x c++ - -v` include-directory probes with those flags, one of them cannot resolve <cstdint>,
	# and its "fatal error" stderr was pasted into local_config_cc/BUILD as include directories, which broke
	# the Starlark syntax (attempt 9). So it is a --cxxopt/--host_cxxopt pair (target + exec configuration).
	# Setting BAZEL_CXXOPTS drops its default -std=c++14, which is fine: TF passes -std=c++17 itself.
	# -isystem/usr/include/jsoncpp: systemlibs/jsoncpp.BUILD only adds -ljsoncpp and expects "json/json.h" on the
	# default include path; Gentoo installs dev-libs/jsoncpp headers under /usr/include/jsoncpp/ (attempt 10).
	# Both fixes go into the auto-configured toolchain (BAZEL_CXXOPTS / BAZEL_CONLYOPTS, colon-separated), not
	# into --copt/--host_copt: Bazel 7.7 did not carry --host_copt into the exec configuration, so tools such
	# as @xla//xla:packing [for tool] were still compiled without the define (attempt 6). CONLYOPTS reaches
	# C files only, so the C-only -Wno-error group never meets a C++ compile (which would reject the name).
	# Host CFLAGS (-march/-mtune) go to Bazel as copts; -pipe/-O*/hardening flags are Bazel's business.
	# Every bazelrc line needs a command word: a bare "--copt=..." is "invalid command name" (attempt 2, 2026-10-21).
	local cflag copts=
	for cflag in ${CFLAGS}; do
		case ${cflag} in
			-march=*|-mtune=*|-mno-*|-mavx*|-mfma) copts+="build --copt=${cflag}"$'\n'"build --host_copt=${cflag}"$'\n' ;;
		esac
	done

	local ram_mb
	ram_mb=$(awk '/MemTotal/ {print int($2 / 1024 * 0.6)}' /proc/meminfo)

	cat > "${T}/gentoo.bazelrc" <<-EOF || die
		startup --output_user_root=${TF_BAZEL_CACHE}/output_user_root
		startup --host_jvm_args=-Xmx4g
		common --disk_cache=${TF_BAZEL_CACHE}/disk_cache
		common --config=clang_local
		common --repo_env=CC=${clang_bin}/clang
		common --repo_env=CXX=${clang_bin}/clang++
		common --repo_env=BAZEL_COMPILER=${clang_bin}/clang
		common --action_env=CC=${clang_bin}/clang
		common --action_env=CXX=${clang_bin}/clang++
		common --action_env=CLANG_COMPILER_PATH=${clang_bin}/clang
		common --repo_env=HERMETIC_PYTHON_VERSION=${EPYTHON#python}
		common --repo_env=TF_SYSTEM_LIBS=$(IFS=,; echo "${TF_SYSLIBS[*]}")
		common --define=PREFIX=${EPREFIX}/usr
		common --jobs=$(makeopts_jobs)
		common --local_resources=memory=${ram_mb}
		common --verbose_failures
		common --color=no --curses=no --show_progress_rate_limit=60
		common --noshow_loading_progress
		common --repo_env=BAZEL_CXXOPTS=-DHWY_DISABLED_TARGETS=(HWY_AVX3|HWY_AVX3_DL|HWY_AVX3_ZEN4|HWY_AVX3_SPR|HWY_AVX10_2):-isystem${T}/cuda-shim
		build --cxxopt=-includecstdint
		build --host_cxxopt=-includecstdint
		build --cxxopt=-isystem/usr/include/jsoncpp
		build --host_cxxopt=-isystem/usr/include/jsoncpp
		common --repo_env=BAZEL_CONLYOPTS=-Wno-error=incompatible-pointer-types-discards-qualifiers
		${copts}
	EOF

	if use cuda; then
		# rules_ml_toolchain reads LOCAL_CUDA_PATH / LOCAL_CUDNN_PATH as unpacked redistributions: it symlinks
		# the subdirectories include/ bin/ lib/ nvvm/ and fails on the first missing one ("/opt/cuda/lib
		# directory doesn't exist!", attempt 11). Gentoo's toolkit has lib64 -> targets/x86_64-linux/lib and no
		# lib, and dev-libs/cudnn lives inside the same tree, so stage a symlink farm with the expected names.
		# The driver stub (libcuda) and NCCL are not installed here and stay hermetic (downloaded).
		# override_include_cuda_libs: --config=cuda links the CUDA libraries into TF's shared objects
		# (include_cuda_libs=true) and the wheel rule then refuses to package unless told so; the alternative
		# --config=cuda_wheel is the PyPI model (nvidia-* pip wheels at runtime), wrong for a system toolkit.
		# TF's own CI uses the same override for its local-library CUDA 13 wheel test (.bazelrc).
		# Every local redist (cudart, cupti, nvcc, nvml, ...) draws from the SAME root, so include/ and lib/ are
		# merged directories: Gentoo keeps CUPTI apart in extras/CUPTI/{include,lib64} ("cupti_result.h file
		# not found", GPU attempt 3), while an unpacked redistribution has it in the top-level include/ and lib/.
		local cuda_local=${T}/cuda-local cuda_root=${EPREFIX}/opt/cuda entry src
		mkdir -p "${cuda_local}"/{include,lib} || die
		for entry in "${cuda_root}"/*; do
			case ${entry##*/} in
				include|lib|lib64) ;;
				*) ln -sfn "${entry}" "${cuda_local}/${entry##*/}" || die ;;
			esac
		done
		for src in "${cuda_root}"/include "${cuda_root}"/extras/CUPTI/include; do
			for entry in "${src}"/*; do [[ -e ${entry} ]] && { ln -sfn "${entry}" "${cuda_local}/include/${entry##*/}" || die; }; done
		done
		for src in "${cuda_root}"/lib64 "${cuda_root}"/extras/CUPTI/lib64; do
			for entry in "${src}"/*; do [[ -e ${entry} ]] && { ln -sfn "${entry}" "${cuda_local}/lib/${entry##*/}" || die; }; done
		done
		for entry in include bin lib nvvm; do
			[[ -d ${cuda_local}/${entry}/ ]] || die "${EPREFIX}/opt/cuda has no ${entry}/ (needed as ${cuda_local}/${entry})"
		done
		[[ -e ${cuda_local}/include/cudnn.h ]] || die "cudnn.h not under ${cuda_root}/include (dev-libs/cudnn)"
		[[ -e ${cuda_local}/include/cupti_result.h && -e ${cuda_local}/lib/libcupti.so ]] || die "CUPTI not under ${cuda_root}/extras/CUPTI"
		# clang 22 replaces the toolkit's sm_32_intrinsics.hpp with its own __clang_cuda_intrinsics.h, whose
		# cache-hint loads __ldcg/__ldcs/__ldcv have `long` overloads but no `unsigned long` twins (uint64_t on
		# LP64): XLA's RAFT top-k fails with "no matching function for call to '__ldcs'" (GPU attempt 4). The
		# toolkit header has them but is never consulted. Force-included shim; a no-op outside CUDA compiles.
		cat > "${T}/cuda-shim/cuda-ul-shim.h" <<-'EOF' || die
			#if defined(__clang__) && defined(__CUDA__) && defined(__SM_32_INTRINSICS_HPP__)
			#if !defined(__CUDA_ARCH__) || __CUDA_ARCH__ >= 320
			inline __device__ unsigned long __ldcg(const unsigned long *__p) { return (unsigned long)__ldcg((const long *)__p); }
			inline __device__ unsigned long __ldcv(const unsigned long *__p) { return (unsigned long)__ldcv((const long *)__p); }
			inline __device__ unsigned long __ldcs(const unsigned long *__p) { return (unsigned long)__ldcs((const long *)__p); }
			#endif
			#endif
		EOF
		cat >> "${T}/gentoo.bazelrc" <<-EOF || die
			build --cxxopt=-include${T}/cuda-shim/cuda-ul-shim.h
			build --host_cxxopt=-include${T}/cuda-shim/cuda-ul-shim.h
			common --config=cuda_clang
			common --config=cuda13_version
			common --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES=sm_120,compute_120
			common --repo_env=LOCAL_CUDA_PATH=${cuda_local}
			common --repo_env=LOCAL_CUDNN_PATH=${cuda_local}
			common --repo_env=TF_CUDA_CLANG=1
			common --@local_config_cuda//cuda:override_include_cuda_libs=true
		EOF
	fi
	einfo "Bazel settings (${T}/gentoo.bazelrc):"
	cat "${T}/gentoo.bazelrc" || die
}

src_compile() {
	# src_* phases run inside the Portage sandbox; the persistent Bazel state lives outside WORKDIR
	# (2026-10-21: first attempt died on "ACCESS DENIED: mkdir .../output_user_root/<hash>")
	addwrite "${TF_BAZEL_CACHE}"
	export BAZELISK_HOME="${TF_BAZEL_CACHE}/bazelisk"
	export HOME="${TF_BAZEL_CACHE}"
	local wheel_name=tensorflow_cpu
	use cuda && wheel_name=tensorflow
	bazel --bazelrc="${T}/gentoo.bazelrc" build \
		--repo_env=WHEEL_NAME=${wheel_name} \
		//tensorflow/tools/pip_package:wheel \
		|| die "bazel build failed (state kept in ${TF_BAZEL_CACHE}; re-emerge resumes)"
	bazel --bazelrc="${T}/gentoo.bazelrc" shutdown || ewarn "bazel shutdown failed"
}

src_install() {
	local whl
	whl=$(find -L bazel-bin/tensorflow/tools/pip_package/wheel_house -name '*.whl' -print -quit) || die
	[[ -n ${whl} ]] || die "no wheel under bazel-bin/tensorflow/tools/pip_package/wheel_house"
	einfo "installing ${whl##*/}"
	${EPYTHON} -m installer --destdir="${D}" "${whl}" || die
	python_optimize
}

pkg_postinst() {
	elog "Bazel state stays in ${TF_BAZEL_CACHE} (several GB) for faster rebuilds; remove it when done."
	elog "Check: python3 -c 'import tensorflow as tf; print(tf.__version__, tf.config.list_physical_devices())'"
	use cuda || elog "CPU build (wheel tensorflow_cpu). USE=cuda builds the GPU wheel for sm_120."
}
