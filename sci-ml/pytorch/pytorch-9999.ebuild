# Copyright 2022-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_EXT=1
inherit distutils-r1 git-r3 prefix

DESCRIPTION="Tensors and Dynamic neural networks in Python (live)"
HOMEPAGE="https://pytorch.org/"
EGIT_REPO_URI="https://github.com/pytorch/${PN}.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/${PN}"
S="${WORKDIR}/${PN}"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"
RESTRICT="test"

REQUIRED_USE=${PYTHON_REQUIRED_USE}

# ABI lock-step: the python bindings link against the libtorch that caffe2
# built and cached in /var/lib/caffe2/CMakeCache.txt.  A live frontend built
# from git HEAD MUST pair with caffe2-9999 (same HEAD) — a stable caffe2 tag
# would produce a C++ ABI mismatch.  Hence the exact ~9999 pin (no || floor).
RDEPEND="
	${PYTHON_DEPS}
	~sci-ml/caffe2-9999[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/sympy[${PYTHON_USEDEP}]
		dev-python/typing-extensions[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}
	$(python_gen_cond_dep '
		dev-python/pyyaml[${PYTHON_USEDEP}]
	')
"

# Version-prefixed patches track the latest stable base; if a HEAD bump breaks
# them, refresh the patch (and bump the prefix) — same policy as caffe2-9999.
PATCHES=(
	"${FILESDIR}"/${PN}-2.9.0-dontbuildagain.patch
	"${FILESDIR}"/${PN}-2.10.0-cpp-extension-multilib.patch
)

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	# Replace placeholders added by cpp-extension.patch
	sed -e "s|%LIB_DIR%|$(get_libdir)|g" \
		-i torch/utils/cpp_extension.py || die

	# Set build dir for pytorch's setup — reuse caffe2's cmake cache
	sed -e "/BUILD_DIR/s|build|/var/lib/caffe2/|" \
		-i tools/setup_helpers/env.py || die

	# Drop legacy from pyproject.toml
	sed -e "/build-backend/s|:__legacy__||" \
		-i pyproject.toml || die

	distutils-r1_src_prepare

	hprefixify tools/setup_helpers/env.py
}

python_compile() {
	PYTORCH_BUILD_VERSION=${PV} \
	PYTORCH_BUILD_NUMBER=0 \
	USE_SYSTEM_LIBS=ON \
	CMAKE_BUILD_DIR="${BUILD_DIR}" \
	distutils-r1_python_compile develop sdist
}

python_install() {
	USE_SYSTEM_LIBS=ON distutils-r1_python_install
}
