# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd desktop xdg-utils

DESCRIPTION="Ollama - get up and running with large language models."
HOMEPAGE="https://ollama.com/"
LICENSE="MIT"
SLOT="0"

IUSE="+systemd cpuonly"
REQUIRED_USE="
    cpuonly? ( systemd )
"
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

REQUIRES_EXCLUDE="libamdhip64.so.6 libhipblas.so.2 librocblas.so.4"

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
    #chown -R genai:genai "${D}${INSTALL_DIR}"
    cd "${D}"
    # /opt/rocm-6.3.3
    # /opt/rocm-6.3.3/lib/llvm/bin/../../../lib
    _patchelf_paths=(
        "lib",
        "lib/llvm",
        "lib/llvm/bin",
        "lib/ollama",
        "lib/ollama/cuda_v12",
        "lib/ollama/cuda_v13",
        "/opt/rocm-6.3.3",
        "/opt/rocm-6.3.3/lib",
        "/opt/rocm-6.3.3/lib/llvm",
        "/opt/rocm-6.3.3/lib/llvm/bin",
    )
    for _index in "${!_patchelf_paths[@]}"
    do
        _patchelf_paths[${_index}]="${INSTALL_DIR}/${_patchelf_paths[${_index}]}"
    done
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "./usr/lib/ollama/libggml-hip.so" || die
    if use systemd; then
        OLLAMA_WAS_ACTIVE=$(systemctl is-active ollama)
        #einfo "Stopping systemd service."
        #systemctl stop ollama.service
        einfo "Installing new systemd service."
        if use cpuonly; then
            systemd_newunit "${FILESDIR}"/ollama-cpu.service ollama.service
        else
            systemd_newunit "${FILESDIR}"/ollama.service ollama.service
        fi
        #einfo "Restarting systemd daemon."
        #systemctl daemon-reload
        einfo "Systemd daemon has to be reloaded: \"sudo systemctl daemon-reload\""
        einfo "Don't forget to restart ollama systemd service if it was running before the update. E.g. \"sudo systemctl restart ollama.service\""
        #if [ "$OLLAMA_WAS_ACTIVE" == "active" ]; then
        #    einfo "Starting again systemd service."
        #    systemctl start ollama.service
        #else
        #    einfo "Don't forget to start systemd service when ready: \"sudo systemctl start ollama.service\""
        #fi
    fi
}
