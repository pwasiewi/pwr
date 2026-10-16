# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=no
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

# Copied from ::stuff triton-bin-3.7.1 (2026-10-16) and bumped for torch v2.15.0-rc5, whose
# .ci/docker/triton_version.txt pins 3.9.0 (triton commit aad2a60d). 3.9.0 is not on PyPI yet;
# the PyTorch test index ships ONE stable-ABI wheel (cp312-abi3) that serves 3.12-3.14.
# Switch SRC_URI to files.pythonhosted.org once 3.9.0 is published there.
# Research: ~/Claude/llm/night/research/37-mlstack-prereqs-1016.md

MY_PN=${PN%-bin}
WHL="${MY_PN}-${PV}-cp312-abi3-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl"

DESCRIPTION="Triton GPU programming language and compiler (binary wheels)"
HOMEPAGE="
	https://github.com/triton-lang/triton
	https://pypi.org/project/triton/
"
SRC_URI="https://download.pytorch.org/whl/test/${WHL} -> ${P}-cp312-abi3.whl"
S="${WORKDIR}"

# The wheel bundles LLVM/MLIR and proprietary CUDA tools under backends/nvidia.
LICENSE="MIT Apache-2.0-with-LLVM-exceptions NVIDIA-CUDA"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="!!dev-python/triton"
QA_PREBUILT="usr/lib/python3.*/site-packages/triton/*"

src_unpack() {
	# Prevent distutils-r1 from unpacking the wheel into S; installer reads it per impl.
	mkdir -p "${S}/wheel" || die
	cp "${DISTDIR}/${P}-cp312-abi3.whl" "${S}/wheel/${WHL}" || die
}

src_install() {
	python_foreach_impl install_wheel
}

install_wheel() {
	# One abi3 wheel for every implementation.
	${EPYTHON} -m installer --destdir="${D}" "${S}/wheel/${WHL}" || die
	# Drop generic, multi-impl-clobbered profiler scripts; its module remains.
	rm -f "${D}"/usr/bin/proton "${D}"/usr/bin/proton-viewer || die
	# installer does not byte-compile.
	python_optimize
}
