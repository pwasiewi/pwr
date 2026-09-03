# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the ntfy notification server"
ACCT_USER_ID=-1
ACCT_USER_HOME=/var/lib/ntfy
ACCT_USER_HOME_PERMS=0750
ACCT_USER_GROUPS=( ntfy )

KEYWORDS="~amd64 ~arm64"

acct-user_add_deps
