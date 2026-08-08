# Copyright 2022-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Upstream moved to scikit-build-core (PEP 517) — setup.py is a stub and the
# whole tools/setup_helpers machinery (env.py, cmake.py) is gone, taking the
# old develop+sdist packaging flow and the BUILD_DIR sed with it (2026-08-08).
#
# The DIVISION OF LABOUR is unchanged: caffe2-9999 builds and installs ALL
# compiled artifacts (libtorch, torch/_C.*.so, the .pyi stubs, torch/include)
# from its cmake tree in /var/lib/caffe2 — this package ships the pure-python
# half only (torch/, torchgen/, functorch/ + the torchrun/torchfrtrace entry
# points; on the previous flow it installed zero .so files). Hence
# wheel.cmake=false in src_prepare: scikit-build-core packs the three package
# trees upstream lists in [tool.scikit-build.wheel] without ever running
# cmake — nothing rebuilds, nothing writes outside the sandbox, and the old
# dontbuildagain.patch (which cut build_pytorch() out of the big setup.py for
# the same reason) is obsolete.
#
# Requires >=dev-python/scikit-build-core-1.0 (upstream's declared floor: the
# [tool.scikit-build.env] table and dynamic-metadata need it).
DISTUTILS_USE_PEP517=scikit-build-core
PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1 git-r3

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
	"${FILESDIR}"/${PN}-2.10.0-cpp-extension-multilib.patch
)

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	# Replace placeholders added by cpp-extension.patch
	sed -e "s|%LIB_DIR%|$(get_libdir)|g" \
		-i torch/utils/cpp_extension.py || die

	# Packaging-only wheel: the compiled half is caffe2's job (see the
	# header). Written INTO the [tool.scikit-build.wheel] section — a
	# top-level 'wheel.cmake' dotted key would pre-declare the table and
	# TOML forbids the section header re-opening it ("Cannot declare twice").
	sed -e '/^\[tool\.scikit-build\.wheel\]$/a cmake = false' \
		-i pyproject.toml || die
	grep -q '^cmake = false$' pyproject.toml ||
		die "pyproject.toml drifted — could not disable the cmake half of the wheel"

	distutils-r1_src_prepare
}

python_compile() {
	# Read by the dynamic-metadata version provider (tools/metadata/version)
	local -x PYTORCH_BUILD_VERSION=${PV} PYTORCH_BUILD_NUMBER=0
	distutils-r1_python_compile
}
