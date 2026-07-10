# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=9

DESCRIPTION="An open-source AI agent that lives in your terminal"
HOMEPAGE="https://github.com/QwenLM/qwen-code"
SRC_URI="
	amd64? (
		https://github.com/QwenLM/qwen-code/releases/download/v${PV}/qwen-code-linux-x64.tar.gz
			-> ${P}-linux-x64.tar.gz
	)
	arm64? (
		https://github.com/QwenLM/qwen-code/releases/download/v${PV}/qwen-code-linux-arm64.tar.gz
			-> ${P}-linux-arm64.tar.gz
	)
"
S="${WORKDIR}/qwen-code"

# Apache-2.0: qwen-code itself; MIT/BSD: bundled Node.js runtime + node_modules
LICENSE="Apache-2.0 MIT BSD"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

RESTRICT="mirror strip"

QA_PREBUILT="opt/qwen-code/*"

src_prepare() {
	default
	# Prune vendored binaries for foreign platforms (darwin/win32 ripgrep etc.)
	rm -rf lib/vendor/ripgrep/{arm64-darwin,x64-darwin,x64-win32} || die
	if use amd64; then
		rm -rf lib/vendor/ripgrep/arm64-linux || die
	else
		rm -rf lib/vendor/ripgrep/x64-linux || die
	fi
}

src_install() {
	local destdir="${ED}/opt/qwen-code"
	dodir /opt/qwen-code
	# cp -a preserves the executable bits (bin/qwen, node/bin/node, ripgrep)
	cp -a . "${destdir}/" || die

	dodoc README.md
	rm "${destdir}"/README.md || die

	# bin/qwen resolves its ROOT from dirname "$0" WITHOUT following symlinks —
	# a dosym in /usr/bin would yield ROOT=/usr and break it, hence a wrapper.
	cat > "${T}"/qwen <<-EOF || die
		#!/bin/sh
		exec /opt/qwen-code/bin/qwen "\$@"
	EOF
	dobin "${T}"/qwen
}

pkg_postinst() {
	elog "Self-contained release (bundled Node.js runtime) in /opt/qwen-code/."
	elog "Local llama-server backend: eval exports from 'aillama env', then:"
	elog "  OPENAI_MODEL=<profile> qwen"
}
