# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#DISTUTILS_USE_PEP517=setuptools
#PYTHON_COMPAT=( python3_{10..12} )

inherit systemd desktop xdg-utils

DESCRIPTION="Ollama - get up and running with large language models."
HOMEPAGE="https://ollama.com/"
LICENSE="MIT"
SLOT="0"

IUSE="+systemd cpuonly"

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
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/usr"

MY_PV="${PV//_}"
MY_PN="ollama"
MY_P=${MY_PN}-${MY_PV}
KEYWORDS="~amd64 ~arm64"
SRC_URI="https://github.com/ollama/ollama/releases/download/v${PV}/ollama-linux-${ARCH}.tgz -> ${P}.gh.tgz"
S="${WORKDIR}/"


src_prepare() {
    default
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    cp -R -f "${WORKDIR}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    chown -R genai:genai "${D}${INSTALL_DIR}"
    #cp -f "${FILESDIR}/swarmui_runner.sh" "${D}${INSTALL_DIR}"
    #chmod +x "${D}${INSTALL_DIR}/swarmui_runner.sh"
    #if use desktop; then
    #    insinto /usr/share/applications
    #    doicon -s 256 "${FILESDIR}/swarmui-web.png"
    #    doins "${FILESDIR}/swarmui.desktop"
    #fi
    #cp -f "${FILESDIR}/dotnet-install.sh"  "${D}${INSTALL_DIR}/launchtools/"
    #chmod +x "${D}${INSTALL_DIR}/launchtools/dotnet-install.sh"
    #echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}package_version.txt"
    #dosym "${INSTALL_DIR}swarmui_runner.sh" "usr/bin/swarmui-web"
    cd "${D}"
    if use systemd; then
        if use cpuonly; then
            systemd_newunit "${FILESDIR}"/ollama-cpu.service ollama.service
        else
            systemd_newunit "${FILESDIR}"/ollama.service ollama.service
        fi
    fi
}
