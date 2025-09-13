# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#inherit systemd

DESCRIPTION="Ollama - get up and running with large language models - additional amd package"
HOMEPAGE="https://ollama.com/"
LICENSE="MIT"
SLOT="0"

#IUSE="+systemd"
IUSE=""

BEPEND="virtual/pkgconfig"

RDEPEND="\
    acct-user/genai\
    acct-group/genai\
"

DEPEND="\
    ${RDEPEND}\
    dev-vcs/git\
    net-misc/curl\
    net-misc/wget\
    sci-ml/ollama\
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/usr"

MY_PV="${PV//_}"
MY_PN="ollama"
MY_P=${MY_PN}-${MY_PV}
KEYWORDS="~amd64"
SRC_URI="https://github.com/ollama/ollama/releases/download/v${PV}/ollama-linux-${ARCH}-rocm.tgz -> ${P}.gh.tgz"
S="${WORKDIR}/"


src_prepare() {
    default
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    cp -R -f "${WORKDIR}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    chown -R genai:genai "${D}${INSTALL_DIR}"
    cd "${D}"
    #if use systemd; then
    #    systemd_newunit "${FILESDIR}"/ollama.service ollama.service
    #fi
}
