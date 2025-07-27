# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
EAPI=8
#
DESCRIPTION="The Kiwix tools is a collection of Kiwix related command line tools."
#
HOMEPAGE="https://kiwix.org/"
#
MYARCH="x86_64"
if [[ ${ARCH} == "amd64" ]]; then
MYARCH="x86_64"
else
if [[ ${ARCH} == "x86" ]]; then
MYARCH="i586"
else
if [[ ${ARCH} == "arm64" ]]; then
MYARCH="aarch"
else
if [[ ${ARCH} == "arm" ]]; then
MYARCH="armv8"
fi
fi
fi
fi
#
MY_PV="${PV//_}"
MY_PN="kiwix-tools"
MY_P=${MY_PN}_linux-${MYARCH}-${MY_PV}
#
SRC_URI="https://download.kiwix.org/release/kiwix-tools/kiwix-tools_linux-${MYARCH}-${PV}.tar.gz -> ${P}.gh.tar.gz"
#
S="${WORKDIR}"
#
LICENSE="GPL-3"
#
SLOT="0"
#
KEYWORDS="~amd64 ~x86 ~arm64 ~arm"
# ~armhf ~armv6 ~armv8
#
#IUSE=""
#
RESTRICT="strip"
#
RDEPEND="\
    acct-user/genai\
    acct-group/genai\
"
#
QA_PREBUILT="*"
#
src_prepare() {
    default
}
#
src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}"
    cp "${WORKDIR}/${MY_P}/kiwix-serve" kiwix-serve || die
    cp "${WORKDIR}/${MY_P}/kiwix-serve" kiwix-search || die
    cp "${WORKDIR}/${MY_P}/kiwix-serve" kiwix-manage || die
    dobin kiwix-serve
    dobin kiwix-search
    dobin kiwix-manage
}
