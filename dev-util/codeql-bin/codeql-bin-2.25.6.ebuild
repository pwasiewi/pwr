# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="GitHub CodeQL static analysis CLI — prebuilt binary with bundled query packs"
HOMEPAGE="https://github.com/github/codeql-cli-binaries"
SRC_URI="
	amd64? (
		https://github.com/github/codeql-cli-binaries/releases/download/v${PV}/codeql-linux64.zip
			-> ${P}-linux-amd64.zip
	)
"

S="${WORKDIR}/codeql"

# codeql binary: GitHub CodeQL Terms and Conditions (free for open-source/research)
# per-language query packs: MIT
# Open-Source-Notices/ covers bundled third-party components
LICENSE="all-rights-reserved MIT"
SLOT="0"
KEYWORDS="-* ~amd64"

RESTRICT="bindist mirror strip"

BDEPEND="app-arch/unzip"

# The main binary is a GraalVM native-image — fully statically linked.
# Per-language extractors (python, javascript, go...) may call language runtimes
# at database-creation time, but those are optional runtime deps.

QA_PREBUILT="opt/codeql/*"

src_install() {
	local destdir="${ED}/opt/codeql"
	dodir /opt/codeql

	# cp -a preserves executable bits set in the zip (doins strips them)
	cp -a . "${destdir}/" || die "cp -a failed"

	# Remove Windows wrapper and docs handled separately
	rm -f "${destdir}/codeql.cmd" || die

	dodoc LICENSE.md
	rm -f "${destdir}/LICENSE.md" || die

	# Wrapper in PATH
	dosym ../../opt/codeql/codeql /usr/bin/codeql
}

pkg_postinst() {
	elog "CodeQL CLI installed to /opt/codeql/codeql"
	elog "Wrapper symlink: /usr/bin/codeql"
	elog ""
	elog "Quick start (Python example):"
	elog "  codeql database create mydb --language=python --source-root=."
	elog "  codeql database analyze mydb python-security-and-quality.qls \\"
	elog "    --format=sarif-latest --output=results.sarif"
	elog ""
	elog "Supported languages: C/C++, C#, Go, Java/Kotlin, JavaScript/TypeScript,"
	elog "  Python, Ruby, Rust, Swift"
	elog ""
	elog "CodeQL CLI is free for open-source and security research use."
	elog "Commercial use on closed-source code requires GitHub Advanced Security."
}
