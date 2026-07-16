# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 go-module

DESCRIPTION="DezKVM – open‑source, multi‑port IP‑KVM"
HOMEPAGE="https://github.com/tobychui/DezKVM"
EGIT_REPO_URI="https://github.com/tobychui/DezKVM.git"
EGIT_BRANCH="master"

LICENSE="MIT"
KEYWORDS="~amd64 ~arm64"
SLOT="0"
RDEPEND="dev-lang/go"

src_compile() {
	go build -o "$T/dezkvm" ./cmd/dezkvm || die "go build failed"
}

src_install() {
	# Install the binary
	dobin "$T/dezkvm"
}

pkg_postinst() {
	elog "DezKVM binary installed. Refer to the project README for usage instructions."
}
