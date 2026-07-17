# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit edo git-r3 optfeature

DESCRIPTION="An open-source AI agent that lives in your terminal (built from source)"
HOMEPAGE="https://github.com/QwenLM/qwen-code"
EGIT_REPO_URI="https://github.com/pwasiewi/qwen-code.git"
EGIT_BRANCH="fix/peg-native-stream-retry"

# Apache-2.0: qwen-code; MIT/BSD: node_modules inlined by esbuild;
# Unlicense: vendored ripgrep (MIT || Unlicense)
LICENSE="Apache-2.0 MIT BSD Unlicense"
SLOT="0"
KEYWORDS=""

# network-sandbox: npm ci fetches ~1900 packages at build time — vendoring
# them in SRC_URI is impractical for a private overlay.
# test: vitest suite needs network and a long runtime.
RESTRICT="network-sandbox test"

# engines.node >= 22 in package.json
RDEPEND="
	>=net-libs/nodejs-22
	!app-misc/qwen-code-bin
"
BDEPEND=">=net-libs/nodejs-22[npm]"

# vendored ripgrep binaries are prebuilt upstream artifacts
QA_PREBUILT="opt/qwen-code/vendor/ripgrep/*"

src_prepare() {
	default
	# Prune vendored ripgrep for foreign platforms before bundling —
	# copy_bundle_assets.js copies this directory verbatim into dist/vendor/
	local vendor="packages/core/vendor/ripgrep"
	rm -rf "${vendor}"/{arm64-darwin,x64-darwin,x64-win32} || die
	if use amd64; then
		rm -rf "${vendor}"/arm64-linux || die
	else
		rm -rf "${vendor}"/x64-linux || die
	fi
}

src_compile() {
	export HOME="${T}"
	export npm_config_cache="${T}/npm-cache"
	# npm's "prepare" lifecycle (scripts/prepare.js) runs husky + build +
	# bundle during npm ci. Skip it and run the build steps explicitly —
	# same flow as the upstream release workflow.
	export QWEN_SKIP_PREPARE=1

	edo npm ci --no-audit --no-fund
	edo npm run build
	edo npm run bundle
}

src_install() {
	local destdir="${ED}/opt/qwen-code"
	dodir /opt/qwen-code
	# cp -a preserves the executable bit on the vendored ripgrep binary
	cp -a dist/. "${destdir}/" || die

	# The upstream release wrapper runs node with --expose-gc; replicate it
	# with the system Node.js runtime.
	cat > "${T}"/qwen <<-EOF || die
		#!/bin/sh
		exec node --expose-gc "${EPREFIX}/opt/qwen-code/cli.js" "\$@"
	EOF
	dobin "${T}"/qwen

	dodoc README.md
}

pkg_postinst() {
	optfeature "voice input (batch mode fallback)" media-sound/sox
	elog "Built from source; runs on the system Node.js (no bundled runtime)."
	elog "Local llama-server backend: eval exports from 'aillama env', then:"
	elog "  OPENAI_MODEL=<profile> qwen"
}
