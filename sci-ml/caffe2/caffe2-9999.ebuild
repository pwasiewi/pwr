# Copyright 2022-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
ROCM_VERSION=6.1
inherit python-single-r1 cmake cuda flag-o-matic git-r3 prefix rocm

MYPN=pytorch

# caffe2-2.9.0 depends on future version of composable kernel
# TODO: replace it with DEPEND in the future
CK_COMMIT=7fe50dc3da2069d6645d9deb8c017a876472a977
CK_P=composable_kernel-${CK_COMMIT:0:8}

# NOTE (2026-08-07): unlike the released ebuilds, -9999 does NOT substitute a
# fixed flash-attention tarball. The versioned ebuilds pin FLASH_PV=2.7.4
# because a given pytorch release expects exactly that API; git HEAD does not.
# flash-attention changed Flash_fwd_params::philox_args from
#   at::PhiloxCudaState philox_args;   (<=2.7.4, an ATen value)
# to
#   uint64_t philox_args[4];           (raw storage, decoupled from ATen)
# and HEAD's flash_api.cpp placement-news into it:
#   new (params.philox_args) at::PhiloxCudaState(philox_state);
# which against 2.7.4 fails with "no matching function for call to
# operator new(sizetype, at::PhiloxCudaState&)".
# The authoritative pairing is pytorch's own submodule gitlink, which git-r3
# already checks out — so just use it and let the pin travel with the commit.

DESCRIPTION="A deep learning framework"
HOMEPAGE="https://pytorch.org/"
EGIT_REPO_URI="https://github.com/pytorch/${MYPN}.git"
EGIT_CHECKOUT_DIR="${WORKDIR}/${MYPN}"
SRC_URI="
	rocm? (
		https://github.com/ROCm/composable_kernel/archive/${CK_COMMIT}.tar.gz
		-> ${CK_P}.tar.gz
	)
"

S="${WORKDIR}/${MYPN}"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"
IUSE="cuda cusparselt distributed fbgemm flash gloo kineto memefficient
	mimalloc mkl mpi nccl nnpack +numpy onednn openblas opencl openmp qnnpack
	rocm xnnpack"
RESTRICT="test"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	mpi? ( distributed )
	gloo? ( distributed )
	?? ( cuda rocm )
	rocm? (
		|| ( ${ROCM_REQUIRED_USE} )
		memefficient? ( flash )
	)
	cusparselt? ( || ( cuda rocm ) )
	flash? ( || ( cuda rocm ) )
	memefficient? ( || ( cuda rocm ) )
	nccl? ( rocm )
"

RDEPEND="
	${PYTHON_DEPS}
	dev-cpp/abseil-cpp:=
	dev-cpp/gflags:=
	>=dev-cpp/glog-0.5.0:=
	>=dev-libs/cpuinfo-2025.11.14
	dev-libs/libfmt:=
	dev-libs/protobuf:=
	dev-libs/sleef
	sci-ml/onnx
	virtual/lapack
	cuda? (
		dev-libs/cudnn
		>=sci-ml/cudnn-frontend-1.12.0:=
		>=dev-util/nvidia-cuda-toolkit-12.9:=[profiler]
		cusparselt? ( dev-libs/cusparselt )
	)
	fbgemm? ( >=sci-ml/FBGEMM-1.4 )
	gloo? ( >=sci-ml/gloo-2025.06.04[cuda?,rocm?] )
	kineto? ( ~sci-ml/kineto-0.4.0_p20260323 )
	mimalloc? ( dev-libs/mimalloc )
	mpi? ( virtual/mpi )
	nnpack? (
		sci-ml/NNPACK
		dev-libs/pthreadpool
	)
	numpy? ( $(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
	') )
	onednn? ( sci-ml/oneDNN )
	opencl? ( virtual/opencl )
	qnnpack? (
		sci-ml/gemmlowp
		dev-libs/pthreadpool
	)
	rocm? (
		nccl? ( >=dev-libs/rccl-6.3:= <dev-libs/rccl-7.3:= )
		>=dev-util/hip-6.3:=       <dev-util/hip-7.3:=
		>=dev-util/roctracer-6.3:= <dev-util/roctracer-7.3:=
		>=sci-libs/hipBLAS-6.3:=   <sci-libs/hipBLAS-7.3:=[rocsolver(+)]
		>=sci-libs/hipBLASLt-6.3:= <sci-libs/hipBLASLt-7.3:=
		>=sci-libs/hipFFT-6.3:=    <sci-libs/hipFFT-7.3:=
		>=sci-libs/hipRAND-6.3:=   <sci-libs/hipRAND-7.3:=
		>=sci-libs/hipSOLVER-6.3:= <sci-libs/hipSOLVER-7.3:=
		>=sci-libs/hipSPARSE-6.3:= <sci-libs/hipSPARSE-7.3:=
		>=sci-libs/miopen-6.3:=    <sci-libs/miopen-7.3:=
		>=sci-libs/rocBLAS-6.3:=   <sci-libs/rocBLAS-7.3:=
		>=sci-libs/rocRAND-6.3:=   <sci-libs/rocRAND-7.3:=
		>=sci-libs/rocSOLVER-6.3:= <sci-libs/rocSOLVER-7.3:=
		memefficient? ( =sci-libs/aotriton-bin-0.11*:= )
		distributed? ( >=dev-util/rocm-smi-6.3:= <dev-util/rocm-smi-7.3:= )
		cusparselt? ( >=sci-libs/hipsparselt-6.3:= <sci-libs/hipsparselt-7.3:= )
	)
	distributed? (
		!rocm? ( sci-ml/tensorpipe[cuda?] )
		dev-cpp/cpp-httplib:=
	)
	xnnpack? (
		>=sci-ml/XNNPACK-2024.11
		dev-libs/pthreadpool
	)
	mkl? ( sci-libs/mkl )
	openblas? ( sci-libs/openblas )
"

DEPEND="
	${RDEPEND}
	dev-cpp/nlohmann_json
	dev-libs/flatbuffers
	dev-libs/FXdiv
	dev-libs/pocketfft
	dev-libs/psimd
	sci-ml/FP16
	$(python_gen_cond_dep '
		<dev-python/pybind11-3.0.5[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/typing-extensions[${PYTHON_USEDEP}]
	')
	cuda? ( >=dev-libs/cutlass-3.9.2[tools(+)] )
	onednn? ( sci-ml/ideep )
	rocm? (
		>=sci-libs/hipCUB-6.3:=    <sci-libs/hipCUB-7.3:=
		>=sci-libs/rocPRIM-6.3:=   <sci-libs/rocPRIM-7.3:=
		>=sci-libs/rocThrust-6.3:= <sci-libs/rocThrust-7.3:=
	)
	qnnpack? ( dev-libs/clog )
"

# Version-specific patches use caffe2-2.12.0 prefix (latest stable base),
# except removekineto below which is 9999-only (see comment there).
PATCHES=(
	"${FILESDIR}"/${PN}-2.5.1-unbundle_fmt.patch.xz
	"${FILESDIR}"/${PN}-2.5.1-unbundle_kineto.patch.xz
	# 9999-only: pytorch HEAD renamed ${Torch_SOURCE_DIR} to
	# ${CMAKE_SOURCE_DIR} in the PocketFFT block, so the 2.8.0 patch that the
	# released ebuilds still use no longer applies here.
	"${FILESDIR}"/${PN}-9999-unbundle_pocketfft.patch.xz
	"${FILESDIR}"/${PN}-2.5.1-cudnn_include_fix.patch.xz
	"${FILESDIR}"/${PN}-2.4.0-cpp-httplib.patch.xz
	"${FILESDIR}"/${PN}-2.7.0-glog-0.7.1.patch.xz
	"${FILESDIR}"/${PN}-2.12.0-aotriton-fixes.patch.xz
	"${FILESDIR}"/${PN}-2.8.0-rocm-minus-flash.patch.xz
	"${FILESDIR}"/${PN}-2.12.0-rocm-distributed-link.patch.xz
	"${FILESDIR}"/${PN}-2.9.1-torch_cpu.patch.xz
	# 9999-only: upstream inserted the CUPTI/perfetto block where this hunk's
	# trailing context used to be (install(DIRECTORY ...)), in caffe2/
	# CMakeLists.txt. Identical to the 2.10.0 patch otherwise.
	"${FILESDIR}"/${PN}-9999-gentoo.patch.xz
	"${FILESDIR}"/${PN}-2.11.0-mimalloc.patch.xz
	# 9999-specific (not the shared 2.12.0 file, which stays frozen for the
	# pinned v2.12.0/2.12.1 tag builds): live HEAD added XPU_RUNTIME/
	# XPU_DRIVER to KinetoEvent::externalId()'s GPU-activity condition list
	# after the original patch was written, so the shared patch's hunk 3/3
	# stopped applying (rejects at torch/csrc/autograd/profiler_kineto.cpp,
	# "1 out of 1 hunk FAILED" on 2026-07-19). This variant folds
	# XPU_RUNTIME/XPU_DRIVER into the same guarded check. Live ebuild will
	# need this re-synced again whenever upstream shifts that function.
	"${FILESDIR}"/${PN}-9999-removekineto-pr178960.patch.xz

	# stuff overlay only: scrub MKL MPI / cluster libs and force GNU
	# OpenMP threading in caffe2::mkl's public link interface so that
	# downstream consumers (vllm, custom torch C++ ext) link cleanly
	# on hosts with the basic intel-oneapi-mkl package (no Cluster
	# Edition, no Intel Compiler / libiomp5). Drop when an equivalent
	# upstream fix lands. # verified 2026-05-08 against 2.11.0;
	# cmake/public/mkl.cmake context identical at 2.12.0.
	"${FILESDIR}"/${PN}-2.12.0-mkl-public-scrub.patch.xz
)

src_unpack() {
	git-r3_src_unpack
	default
}

src_prepare() {
	# files/*.patch ship xz-compressed to stay under pkgcheck's 50K
	# TotalSizeViolation cap; eapply(1) does not decompress, so expand
	# every files/ patch into ${T} and repoint PATCHES (and the
	# composable-kernel patch below) at the plain-text copies.
	local p b i
	mkdir "${T}"/patches || die
	for p in "${FILESDIR}"/*.patch.xz; do
		b=${p##*/}
		xz -dc "${p}" > "${T}/patches/${b%.xz}" || die
	done
	for i in "${!PATCHES[@]}"; do
		b=${PATCHES[i]##*/}
		PATCHES[i]="${T}/patches/${b%.xz}"
	done

	# No flash-attention tarball swap here — see the SRC_URI note above.
	# git-r3 leaves third_party/flash-attention at the gitlink pytorch HEAD
	# pins, which is the only version its flash_api.cpp compiles against.
	filter-lto #bug 862672

	# Unbundle fmt — remove link suffix and any target_compile_definitions on
	# the (now-absent) bundled fmt/fmt-header-only targets (git HEAD 2.14+ adds these)
	sed -i \
		-e 's|::fmt-header-only||' \
		-e '/target_compile_definitions(fmt[- ]/d' \
		-e '/target_compile_definitions(fmt-header-only/d' \
		c10/CMakeLists.txt \
		cmake/Dependencies.cmake \
		torch/CMakeLists.txt \
		|| die

	# wrap_headers.py (2.14+): called with TORCH_INSTALL_INCLUDE_DIR="include" which
	# expands to /usr/include (all system headers), violating Portage sandbox.
	# The TORCH_STABLE_ONLY guards it adds are not needed at runtime.
	: > tools/wrap_headers.py || die

	# glog 0.6.0: IsGoogleLoggingInitialized is google:: not glog_internal_namespace_::
	# Both Logging.cpp and Exception.cpp (added in 2.13+) need this fix
	sed -i \
		-e '/^namespace glog_internal_namespace_ {$/{N;N;d}' \
		-e 's|::google::glog_internal_namespace_::IsGoogleLoggingInitialized()|::google::IsGoogleLoggingInitialized()|g' \
		c10/util/Exception.cpp \
		c10/util/Logging.cpp \
		|| die

	# tensorpipe is in system, not a build target of caffe2
	sed -e '/target_compile_options_if_supported(tensorpipe/d' -i cmake/Dependencies.cmake || die

	# Drop third_party from CMake tree
	sed -i \
		-e '/add_subdirectory.*third_party/d' \
		CMakeLists.txt \
		cmake/Dependencies.cmake \
		cmake/ProtoBuf.cmake \
		aten/src/ATen/CMakeLists.txt \
		|| die
	# Change libc10* path
	sed -i \
		-e "/EXPORT/s|DESTINATION lib)|DESTINATION $(get_libdir))|" \
		c10/cuda/CMakeLists.txt \
		c10/CMakeLists.txt \
		c10/hip/CMakeLists.txt \
		|| die

	# Change libaotriton path
	sed -i \
		-e "s|}/lib|}/\${CMAKE_INSTALL_LIBDIR}|g" \
		-e "/set(__AOTRITON_LIB/s|lib/|\${CMAKE_INSTALL_LIBDIR}/|g" \
		cmake/External/aotriton.cmake \
		|| die

	# Noisy warnings from Logging.h
	sed -i 's/-Wextra-semi//' cmake/public/utils.cmake || die

	cmake_src_prepare
	pushd torch/csrc/jit/serialization > /dev/null || die
	flatc --cpp --gen-mutable --scoped-enums mobile_bytecode.fbs || die
	popd > /dev/null || die

	# prefixify the hardcoded paths, after all patches are applied
	hprefixify \
		aten/CMakeLists.txt \
		caffe2/CMakeLists.txt \
		cmake/Metal.cmake \
		cmake/Modules/*.cmake \
		cmake/Modules_CUDA_fix/FindCUDNN.cmake \
		cmake/Modules_CUDA_fix/upstream/FindCUDA/make2cmake.cmake \
		cmake/Modules_CUDA_fix/upstream/FindPackageHandleStandardArgs.cmake \
		cmake/public/LoadHIP.cmake \
		cmake/public/cuda.cmake \
		cmake/Dependencies.cmake \
		torch/CMakeLists.txt \
		CMakeLists.txt

	if use rocm; then
		sed -e "s:/opt/rocm:/usr:" \
			-e "s:lib/cmake:$(get_libdir)/cmake:g" \
			-i cmake/public/LoadHIP.cmake || die

		# TODO: delete, when caffe2 depends on systemwide composable_kernel
		sed -e "s:third_party/composable_kernel:../composable_kernel-${CK_COMMIT}:g" \
			-i aten/src/ATen/CMakeLists.txt || die

		# Bug 959808: fix for gfx101x targets
		pushd "${WORKDIR}/composable_kernel-${CK_COMMIT}" > /dev/null || die
		eapply "${T}"/patches/composable-kernel-7fe50dc-expand-isa.patch
		popd > /dev/null || die

		# Workaround for libc++ issue https://github.com/llvm/llvm-project/issues/100802
		sed -e 's/std::memcpy/memcpy/g' -i torch/headeronly/util/Half.h || die

		ebegin "HIPifying cuda sources"
		FBCODE_BUILD_TOOL="buck" ${EPYTHON} tools/amd_build/build_amd.py || die
		eend $?
	fi
}

src_configure() {
	if use cuda && [[ -z ${TORCH_CUDA_ARCH_LIST} ]]; then
		ewarn "WARNING: caffe2 is being built with its default CUDA compute capabilities: 3.5 and 7.0."
		ewarn "These may not be optimal for your GPU."
		ewarn ""
		ewarn "To configure caffe2 with the CUDA compute capability that is optimal for your GPU,"
		ewarn "set TORCH_CUDA_ARCH_LIST in your make.conf, and re-emerge caffe2."
		ewarn "For example, to use CUDA capability 7.5 & 3.5, add: TORCH_CUDA_ARCH_LIST=7.5 3.5"
		ewarn "For a Maxwell model GPU, an example value would be: TORCH_CUDA_ARCH_LIST=Maxwell"
		ewarn ""
		ewarn "You can look up your GPU's CUDA compute capability at https://developer.nvidia.com/cuda-gpus"
		ewarn "or by running /opt/cuda/extras/demo_suite/deviceQuery | grep 'CUDA Capability'"
	fi

	local mycmakeargs=(
		# Release defines -DNDEBUG. PyTorch's default RelWithDebInfo leaves the
		# C/C++ flag vars empty (no NDEBUG), so CPython internal asserts compiled
		# inline into torch/csrc/dynamo/eval_frame.c stay live and abort under
		# Python 3.14 (PyStackRef_DUP: !PyStackRef_IsNull). Force Release.
		-DCMAKE_BUILD_TYPE=Release
		-DBUILD_CUSTOM_PROTOBUF=OFF
		-DBUILD_TEST=OFF
		-DLIBSHM_INSTALL_LIB_SUBDIR="${EPREFIX}"/usr/$(get_libdir)
		-DPython_EXECUTABLE="${PYTHON}"
		-DTORCH_INSTALL_LIB_DIR="${EPREFIX}"/usr/$(get_libdir)
		-DUSE_CCACHE=OFF
		-DUSE_CUDA=$(usex cuda)
		-DUSE_DISTRIBUTED=$(usex distributed)
		-DUSE_FBGEMM=$(usex fbgemm)
		-DUSE_FLASH_ATTENTION=$(usex flash)
		-DUSE_GFLAGS=ON
		-DUSE_GLOG=ON
		-DUSE_GLOO=$(usex gloo)
		-DUSE_ITT=OFF
		-DUSE_KINETO=$(usex kineto)
		-DUSE_KLEIDIAI=OFF # TODO
		-DUSE_MAGMA=OFF # TODO: In GURU as sci-libs/magma
		-DUSE_MEM_EFF_ATTENTION=$(usex memefficient)
		-DUSE_MIMALLOC=$(usex mimalloc)
		-DUSE_MKLDNN=$(usex onednn)
		-DUSE_MPI=$(usex mpi)
		-DUSE_NCCL=OFF
		-DUSE_NNPACK=$(usex nnpack)
		-DUSE_NUMA=OFF
		-DUSE_NUMPY=$(usex numpy)
		-DUSE_OPENCL=$(usex opencl)
		-DUSE_OPENMP=$(usex openmp)
		-DUSE_PYTORCH_QNNPACK=$(usex qnnpack)
		-DUSE_PYTORCH_METAL=OFF
		-DUSE_ROCM=$(usex rocm)
		-DUSE_SYSTEM_CPUINFO=ON
		-DUSE_SYSTEM_EIGEN_INSTALL=ON
		-DUSE_SYSTEM_FP16=ON
		-DUSE_SYSTEM_FXDIV=ON
		-DUSE_SYSTEM_GLOO=ON
		-DUSE_SYSTEM_NVTX=ON
		-DUSE_SYSTEM_ONNX=ON
		-DUSE_SYSTEM_PSIMD=ON
		-DUSE_SYSTEM_PTHREADPOOL=ON
		-DUSE_SYSTEM_PYBIND11=ON
		-DUSE_SYSTEM_SLEEF=ON
		-DUSE_SYSTEM_XNNPACK=$(usex xnnpack)
		-DUSE_TENSORPIPE=$(usex distributed $(usex !rocm))
		-DUSE_UCC=OFF
		-DUSE_VALGRIND=OFF
		-DUSE_XNNPACK=$(usex xnnpack)
		-DUSE_XPU=OFF
		-Wno-dev
	)

	if use mkl; then
		mycmakeargs+=(-DBLAS=MKL)
	elif use openblas; then
		mycmakeargs+=(-DBLAS=OpenBLAS)
	else
		mycmakeargs+=(-DBLAS=Generic -DBLAS_LIBRARIES=)
	fi

	if use cuda; then
		# bug 867706 926116
		cuda_add_sandbox
		addpredict "/dev/char/"

		# Gentoo's FEATURES=ccache only shims the host compiler (gcc/g++), never
		# nvcc, and -DUSE_CCACHE=OFF above stops PyTorch from wiring ccache in
		# itself, so the expensive .cu kernels (cicc/ptxas, Blackwell sm_120)
		# would never be cached. Wire ccache explicitly as the CUDA compiler
		# launcher: on a HEAD bump or an ABI-lockstep rebuild (unchanged .cu
		# sources + nvcc flags) the kernel objects hit the cache and the ~1h
		# build drops sharply. Host C/C++ keeps using the PATH shim (no
		# double-wrap). ccache 4.x caches nvcc generically; the arch is just a
		# hash input. Defaults only; /etc/portage/env wins.
		if [[ ${FEATURES} == *ccache* ]] && type -P ccache >/dev/null; then
			: "${CCACHE_MAXSIZE:=150G}"
			: "${CCACHE_SLOPPINESS:=locale,time_macros,include_file_ctime,include_file_mtime}"
			export CCACHE_MAXSIZE CCACHE_SLOPPINESS
			mycmakeargs+=( -DCMAKE_CUDA_COMPILER_LAUNCHER=ccache )
			einfo "ccache active for nvcc: CCACHE_DIR=${CCACHE_DIR:-<portage default>} MAXSIZE=${CCACHE_MAXSIZE}"
		fi

		mycmakeargs+=(
			-DUSE_CUDNN=ON
			-DTORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-3.5 7.0}"
			-DUSE_NCCL=OFF # TODO: NVIDIA Collective Communication Library
			-DCMAKE_CUDA_FLAGS="$(cuda_gccdir -f | tr -d \")"
			-DUSE_CUSPARSELT=$(usex cusparselt)
		)

		[[ -v CUDACXX ]] && export PYTORCH_NVCC="${CUDACXX}"

		if use flash; then
			export FLASH_ATTENTION_FORCE_BUILD="TRUE"
			export FLASH_ATTN_CUDA_ARCHS="${CUDAARCHS:-${TORCH_CUDA_ARCH_LIST:-3.5 7.0}}"
		fi

	elif use rocm; then
		export PYTORCH_ROCM_ARCH="$(get_amdgpu_flags)"

		if use memefficient; then
			export AOTRITON_INSTALLED_PREFIX="${ESYSROOT}/usr"
		fi

		mycmakeargs+=(
			-DUSE_NCCL=$(usex nccl)
			-DUSE_SYSTEM_NCCL=ON
			-DCMAKE_REQUIRE_FIND_PACKAGE_HIP=ON
			-DCMAKE_DISABLE_FIND_PACKAGE_hipsparselt=$(usex !cusparselt) # disable automagic
			-DUSE_ROCM_CK_SDPA=OFF # requires flash + aiter, works only on gfx90a/gfx942/gfx950
		)

		# ROCm libraries produce too much warnings
		append-cxxflags -Wno-deprecated-declarations -Wno-unused-result -Wno-unused-value
	fi

	if use onednn; then
		mycmakeargs+=(
			-DMKLDNN_FOUND=ON
			-DMKLDNN_LIBRARIES=dnnl
			-DMKLDNN_INCLUDE_DIR="${ESYSROOT}/usr/include/oneapi/dnnl"
		)
	fi

	cmake_src_configure
}

src_compile() {
	PYTORCH_BUILD_VERSION=${PV} \
	PYTORCH_BUILD_NUMBER=0 \
	cmake_src_compile
}

python_install() {
	python_domodule python/torch
	mkdir "${D}"$(python_get_sitedir)/torch/bin || die
	mkdir "${D}"$(python_get_sitedir)/torch/lib || die
	mkdir "${D}"$(python_get_sitedir)/torch/include || die
	ln -s ../../../../../include/torch \
		"${D}$(python_get_sitedir)"/torch/include/torch || die # bug 923269
	ln -s ../../../../../bin/torch_shm_manager \
		"${D}"/$(python_get_sitedir)/torch/bin/torch_shm_manager || die
	ln -s ../../../../../$(get_libdir)/libtorch_global_deps.so \
		"${D}"/$(python_get_sitedir)/torch/lib/libtorch_global_deps.so || die
}

src_install() {
	cmake_src_install

	# Used by pytorch ebuild
	insinto "/var/lib/${PN}"
	doins "${BUILD_DIR}"/CMakeCache.txt

	rm -rf python
	mkdir -p python/torch || die
	cp torch/version.py python/torch/ || die
	python_install

	# PyTorch 2.14 HEAD regressed the install DESTINATION of the torch python
	# bindings: the compiled _C extension and its top-level stubs land in
	# ${EPREFIX}/usr instead of site-packages/torch/, so `import torch` fails
	# to load torch._C (it finds the .pyi stub dir instead). Relocate the
	# extension (critical) plus the stray stubs into torch/, and drop the
	# duplicates that are already provided under torch/ (version.py via
	# python/torch above; _C_flatbuffer/ by the pytorch package).
	# NB: glob against the real ${D}/usr/ path — a bare `_C.cpython-*.so` in the
	# loop list would be matched against CWD (the build dir) and left literal,
	# so the [[ -e ]] test would silently fail and the file would NOT move.
	local sitedir f
	sitedir=$(python_get_sitedir)
	for f in "${D}/usr/"_C.cpython-*.so "${D}/usr/"_VF.pyi "${D}/usr/"return_types.pyi; do
		[[ -e ${f} ]] && { mv "${f}" "${D}${sitedir}/torch/" || die; }
	done
	rm -f "${D}/usr/version.py" || die
	rm -rf "${D}/usr/_C_flatbuffer" || die
}
