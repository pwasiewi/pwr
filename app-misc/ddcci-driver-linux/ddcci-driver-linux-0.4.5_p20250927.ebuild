# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

# A master snapshot, NOT the v0.4.5 tag. The tag is from 2024-07 and predates
# "Adjust to bus_type changes in 6.11+" (e0605c9c) and "Fix build on Linux 6.6+
# without CONFIG_FB_DEVICE" (0233e1ee) — it does not compile against anything
# newer than 6.10, and the kernels this overlay ships are 7.x. Upstream has cut
# no release since, so a pinned commit is the only fetchable form.
COMMIT="bbb7553373f815d78e93a4a9f071ce968563694a"

DESCRIPTION="DDC/CI kernel driver: monitor control over I2C, with a backlight class device"
HOMEPAGE="https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux"
SRC_URI="https://gitlab.com/ddcci-driver-linux/${PN}/-/archive/${COMMIT}/${PN}-${COMMIT}.tar.bz2"
S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# I2C: the ddcci bus rides on the in-kernel i2c adapters (the GPU drivers'
# DDC lines), so without it there is nothing to bind to.
# BACKLIGHT_CLASS_DEVICE: what ddcci-backlight registers into. It is the
# reason to install this at all — ddcutil already talks to monitors through
# /dev/i2c-*; only the kernel driver gives Plasma's brightness slider an
# external monitor to move.
CONFIG_CHECK="I2C BACKLIGHT_CLASS_DEVICE"
ERROR_I2C="ddcci binds to i2c adapters and needs CONFIG_I2C"
ERROR_BACKLIGHT_CLASS_DEVICE="ddcci-backlight needs CONFIG_BACKLIGHT_CLASS_DEVICE"

src_compile() {
	# Order matters and is not incidental: ddcci-backlight's own Makefile
	# points KBUILD_EXTRA_SYMBOLS at ../ddcci/Module.symvers, so ddcci has
	# to be built first or the link silently leaves its symbols undefined.
	# linux-mod-r1 walks modlist in order, which is why they are listed
	# this way round rather than alphabetically.
	local modlist=(
		ddcci=kernel/drivers/i2c:ddcci
		ddcci-backlight=kernel/drivers/video/backlight:ddcci-backlight
	)
	# Upstream defaults KDIR to /lib/modules/$(uname -r)/build — the
	# RUNNING kernel. That is wrong for every image build (the target
	# kernel is never the booted one) and would either fail or, worse,
	# quietly build against the host's kernel.
	local modargs=( KDIR="${KV_OUT_DIR}" )

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	# Neither module has a modalias the kernel can match: ddcci discovers
	# monitors by walking the i2c adapters itself, so nothing ever autoloads
	# it and the driver is simply absent unless something loads it by name.
	# (This is what the "Failed to find module 'ddcci'" line in a stock
	# /etc/modules-load.d/ddc.conf is really complaining about.)
	insinto /usr/lib/modules-load.d
	doins "${FILESDIR}"/ddcci.conf
}
