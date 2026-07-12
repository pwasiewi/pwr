# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit cuda git-r3 optfeature python-single-r1

DESCRIPTION="Zero-dependency C engine and CLI for running GLM-5.2 (744B MoE) locally"
HOMEPAGE="https://github.com/JustVugg/colibri"
EGIT_REPO_URI="https://github.com/JustVugg/colibri.git"
EGIT_BRANCH="main"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS=""
IUSE="cuda"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# coli is a stdlib-only Python 3 CLI wrapper around the glm binary.
RDEPEND="
	${PYTHON_DEPS}
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
"
BDEPEND="
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
"

# cuda.eclass exports its own src_prepare (cuda_src_prepare), which dies
# when dev-util/nvidia-cuda-toolkit (cuda-config) is absent — defining our
# own src_prepare here keeps that call opt-in behind USE=cuda instead of
# firing unconditionally on every build.
src_prepare() {
	default
}

src_compile() {
	local myemakeargs=(
		# c/Makefile's own ARCH knob (CPU tuning: native/x86-64-v3/...) — NOT
		# the same thing as Portage's reserved $ARCH ("amd64"), so it is read
		# from COLIBRI_ARCH here to avoid silently passing "amd64" to gcc's
		# -march=. Override with COLIBRI_ARCH=x86-64-v3 for a portable binary.
		ARCH="${COLIBRI_ARCH:-native}"
	)

	if use cuda; then
		# -arch=native (c/Makefile's CUDA_ARCH default) makes nvcc probe the
		# installed GPU's compute capability at compile time. Override with
		# COLIBRI_CUDA_ARCH=sm_XX to avoid needing GPU access in a sandbox.
		cuda_add_sandbox

		myemakeargs+=(
			CUDA=1
			CUDA_HOME="${EPREFIX}/opt/cuda"
			# Reconstructs c/Makefile's own NVCCFLAGS default (emake-supplied
			# vars override the Makefile's "?=" unconditionally) plus the
			# --compiler-bindir nvcc needs for a host gcc it supports.
			NVCCFLAGS="-O3 -std=c++17 -arch=${COLIBRI_CUDA_ARCH:-native} -Xcompiler=-Wall,-Wextra $(cuda_gccdir -f)"
		)
	fi

	emake -C c "${myemakeargs[@]}" glm
}

src_install() {
	local destdir="${ED}/opt/${PN}"
	dodir "/opt/${PN}"

	# glm sits next to coli: coli.py resolves it via its own __file__ dir.
	cp -a c/glm "${destdir}/" || die
	cp -a c/coli c/doctor.py c/resource_plan.py c/openai_server.py "${destdir}/" || die
	cp -a c/tools "${destdir}/" || die

	# Wrapper, not a symlink: coli.py's HERE = dirname(realpath(__file__)),
	# and a /usr/bin symlink would make HERE resolve to /usr/bin instead of
	# /opt/colibri, breaking the sibling-module imports and the glm lookup.
	cat > "${T}"/coli <<-EOF || die
		#!/bin/sh
		exec ${EPYTHON} "${EPREFIX}/opt/${PN}/coli" "\$@"
	EOF
	dobin "${T}"/coli

	dodoc README.md
}

pkg_postinst() {
	elog "Model weights are NOT packaged (GLM-5.2 int4 conversion is ~372 GB)."
	elog "Point COLI_MODEL at a converted model directory, or run:"
	elog "  coli convert --model <dir-on-NVMe/ext4>"
	optfeature "model conversion (FP8->int4) and quality benchmarking" \
		dev-python/torch dev-python/safetensors dev-python/huggingface_hub dev-python/numpy
	if use cuda; then
		elog "If the build log shows 'Cannot find valid GPU for -arch=native',"
		elog "nvcc could not probe the card during the sandboxed build — set"
		elog "COLIBRI_CUDA_ARCH=sm_120 (Blackwell / RTX 5070 Ti) and re-emerge."
	else
		elog "USE=cuda enables the experimental GPU backend for resident tensors"
		elog "(expert streaming always stays on CPU to avoid a PCIe bottleneck)."
	fi
}
