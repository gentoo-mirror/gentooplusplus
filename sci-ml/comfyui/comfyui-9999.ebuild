# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit systemd desktop xdg-utils python-single-r1

DESCRIPTION="ComfyUI - The most powerful and modular diffusion model GUI, api and backend with a graph/nodes interface."
HOMEPAGE="https://github.com/comfyanonymous/ComfyUI"
LICENSE="GPL-3.0"
SLOT="0"

IUSE="
systemd
desktop
nvidia
amd
intel
ipex
cpu
rdna2
rdna3
amd_mae
python_single_target_python3_10
python_single_target_python3_11
python_single_target_python3_12
python_single_target_python3_13
"

REQUIRED_USE="^^ ( python_single_target_python3_10 python_single_target_python3_11 python_single_target_python3_12 python_single_target_python3_13 )
^^ ( nvidia amd intel ipex cpu )
rdna2? ( amd )
rdna3? ( amd )
"

BEPEND="virtual/pkgconfig"

RDEPEND="\
    acct-user/genai\
    acct-group/genai\
"

# dev-libs/cudnn ?
DEPEND="\
    ${RDEPEND}\
    dev-python/virtualenv\
    dev-vcs/git\
    net-misc/curl\
    net-misc/wget\
    nvidia? ( >=dev-util/nvidia-cuda-toolkit-12.8.0 dev-libs/cudnn x11-drivers/nvidia-drivers )\
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/opt/comfyui/"
CONFIG_DIR="/etc/comfyui"

COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI.git"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/comfyanonymous/ComfyUI.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    #MY_P=${PN}-${MY_PV}
    MY_PN="comfyui"
    MY_P=${MY_PN}-${MY_PV}
    MY_PN="ComfyUI"
    S="${WORKDIR}"
else
    MY_PV="${PV//_}"
    MY_PN="ComfyUI"
    MY_P=${MY_PN}-${MY_PV}
    SRC_URI="https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/v${PV}.tar.gz -> ${MY_P}.gh.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}/"
fi


src_prepare() {
    default
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    mkdir -p "${D}${CONFIG_DIR}"
    if use desktop; then
        mkdir -p "${D}/usr/share/applications/"
    fi
    cp -R -f "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    chown -R genai:genai "${D}${INSTALL_DIR}"
        if use desktop; then
        insinto /usr/share/applications
        doicon -s 256 "${FILESDIR}/comfyui-web-256.png"
        doins "${FILESDIR}/comfyui.desktop"
    fi
    cp -f "${FILESDIR}/comfyui_runner.sh" "${D}${INSTALL_DIR}"
    if ! use nvidia; then
        #export CUDA_VISIBLE_DEVICES=-1
        sed -i 's/#export CUDA_VISIBLE_DEVICES/export CUDA_VISIBLE_DEVICES/' "${D}${INSTALL_DIR}/comfyui_runner.sh"
    fi
    if use cpu; then
        sed -i 's/___default_args___/ --cpu/' "${D}${INSTALL_DIR}/comfyui_runner.sh"
    else
        sed -i 's/___default_args___//' "${D}${INSTALL_DIR}/comfyui_runner.sh"
    fi
    PYTHON_EXECUTABLE="python3.12"
    if use python_single_target_python3_13; then
        PYTHON_EXECUTABLE="python3.13"
    fi
    if use python_single_target_python3_12; then
        PYTHON_EXECUTABLE="python3.12"
    fi
    if use python_single_target_python3_11; then
        PYTHON_EXECUTABLE="python3.11"
    fi
    if use python_single_target_python3_10; then
        PYTHON_EXECUTABLE="python3.10"
    fi
    sed -i "s/__python/${PYTHON_EXECUTABLE}/" "${D}${INSTALL_DIR}/comfyui_runner.sh"
    chmod +x "${D}${INSTALL_DIR}/comfyui_runner.sh"

    cp -f "${FILESDIR}/comfy-install-linux.sh" "${D}${INSTALL_DIR}/comfy-install-linux.sh"
    chmod +x "${D}${INSTALL_DIR}/comfy-install-linux.sh"
    
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}package_version.txt"
    dosym "${EROOT}${INSTALL_DIR}comfyui_runner.sh" "usr/bin/comfyui-web"
    
    einfo "Example configurations will be stored here: \"${EROOT}${CONFIG_DIR}\"."
    cp -f "${FILESDIR}/env.conf.example" "${D}${CONFIG_DIR}/env.conf.example"
    cd "${D}"
    if use systemd; then
        systemd_newunit "${FILESDIR}"/comfyui.service comfyui.service
    fi
    cd "${D}${INSTALL_DIR}"
    rm -rf .ci
    rm -rf .github
    rm -f .gitattributes
    rm -f .gitignore
    chown -R genai:genai "${D}${INSTALL_DIR}"
}

pkg_postinst() {
    pkg_config
}

pkg_config() {
    die() { echo "$*" 1>&2 ; exit 1; }
    cd "${EROOT}${INSTALL_DIR}"
    CHECK_GENAI_UPTODATE=$(groups genai | grep video)
    if [[ -z "${CHECK_GENAI_UPTODATE}" ]]; then
        ewarn ""
        ewarn ""
        ewarn "!!! Please add user genai to group video: \"sudo gpasswd -a genai video\" !!!"
        ewarn "ComfyUI most probably won't install properly due to this issue, so it is recommended to add user as mentioned above to a group and then re-run installation again."
        ewarn ""
        ewarn ""
    fi
    elog "Installing ComfyUI..."
    GPU_TYPE=""
    if use amd; then
        GPU_TYPE="amd"
        if use rdna2; then
            GPU_TYPE="amd2"
        fi
        if use rdna3; then
            GPU_TYPE="amd3"
        fi
    fi
    if use nvidia; then
        GPU_TYPE="nv"
    fi
    if use intel; then
        GPU_TYPE="intel"
    fi
    if use ipex; then
        GPU_TYPE="ipex"
    fi
    if use cpu; then
        GPU_TYPE="cpu"
    fi
    PYTHON_EXECUTABLE="python3.12"
    if use python_single_target_python3_13; then
        PYTHON_EXECUTABLE="python3.13"
    fi
    if use python_single_target_python3_12; then
        PYTHON_EXECUTABLE="python3.12"
    fi
    if use python_single_target_python3_11; then
        PYTHON_EXECUTABLE="python3.11"
    fi
    if use python_single_target_python3_10; then
        PYTHON_EXECUTABLE="python3.10"
    fi
    sudo -u genai ./comfy-install-linux.sh "${GPU_TYPE}" "${PYTHON_EXECUTABLE}"
    if use amd_mae; then
        sed -i "/import os/a os.environ\['TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL'\] = '1'" "./main.py"
        echo "args.use_pytorch_cross_attention = True
" >> ./comfy/cli_args.py
    fi
    elog "Finished installing ComfyUI."
    if use desktop; then
        elog "Registering desktop application."
        update-desktop-database /usr/share/applications
        update-mime-database /usr/share/mime
        xdg_icon_cache_update
        elog "Registering desktop application done."
    fi
	elog "ComfyUI Web App was installed into a virtualenv built into ${EROOT}${INSTALL_DIR}"
	elog ""
	elog "It is run by the user and group genai/genai."
	elog "It may install quite a few dependencies on a first run - expect it to take some time."
	elog "In order to run, please"
	if use systemd; then
	    elog "enable and run the comfyui.service systemd service ( e.g. sudo systemctl enable --now comfyui.service )."
	    elog "Alternatively, you may"
	fi
	elog "run using a user \"genai\" the bash script ${EROOT}/usr/bin/comfyui-web ( e.g. sudo -u genai ${EROOT}/usr/bin/comfyui-web )."
	elog ""
	elog "Hope it works. Enjoy!"
	if use systemd; then
        systemctl daemon-reload
	fi
}

pkg_prerm() {
    if use systemd; then
        einfo "Stopping systemd services."
        systemctl daemon-reload
        systemctl stop comfyui.service
        systemctl disable comfyui.service
    fi
    cd "${EROOT}${INSTALL_DIR}"
    rm -f configured
    rm -rf venv
    find . -type d -name __pycache__ -prune -exec rm -rf {}  \;
}

pkg_postrm() {
    if use desktop; then
	    xdg_icon_cache_update
	fi
    if use systemd; then
        einfo "Restarting systemd daemon."
        systemctl daemon-reload
    fi
    if [[ -d "${EROOT}${INSTALL_DIR}" ]]; then
        ewarn ""
        ewarn "The directory \"${EROOT}${INSTALL_DIR}\" was not completely removed."
        ewarn "If that is not the expected behaviour, please remove it manually."
        ewarn ""
    fi
    if [[ -d "${EROOT}${CONFIG_DIR}" ]]; then
        ewarn ""
        ewarn "The uninstall action did not remove the configuration files."
        ewarn "They were left intact here: \"${EROOT}${CONFIG_DIR}\""
        ewarn ""
    fi
}
