# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="User for Media Servers and other media operations"
ACCT_USER_ID=664
ACCT_USER_GROUPS=( ${PN} )
ACCT_USER_HOME="/opt/media"

acct-user_add_deps
