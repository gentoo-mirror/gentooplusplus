# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit systemd desktop xdg-utils python-single-r1

DESCRIPTION="Stable Diffusion SwarmUI web application"
HOMEPAGE="https://swarmui.net/"
LICENSE="MIT"
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
+comfyui
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

INSTALL_DIR="/opt/swarmui/"
CONFIG_DIR="/etc/swarmui"

COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI.git"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/mcmonkeyprojects/SwarmUI"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="sd-sarmui-web"
    S="${WORKDIR}"
else
    MY_PV="${PV//_}"
    MY_PN="sd-swarmui-web"
    MY_P=${MY_PN}-${MY_PV}
    SRC_URI="https://github.com/mcmonkeyprojects/SwarmUI/archive/refs/tags/${PV}-Beta.tar.gz -> ${MY_P}.gh.tar.gz"
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
    mkdir -p "${D}${INSTALL_DIR}/launchtools"
    if use desktop; then
        mkdir -p "${D}/usr/share/applications/"
    fi
    if [[ ${PV} == 9999 ]]; then
        cp -R -f "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    else
        cp -R -f "${WORKDIR}/SwarmUI-${MY_PV}-Beta/." "${D}${INSTALL_DIR}" || die "Install failed!"
    fi
    chown -R genai:genai "${D}${INSTALL_DIR}"
    if use nvidia; then
        cp -f "${FILESDIR}/swarmui_runner.sh" "${D}${INSTALL_DIR}"
    else
        cp -f "${FILESDIR}/swarmui_runner_no_cuda.sh" "${D}${INSTALL_DIR}/swarmui_runner.sh"
    fi
    chmod +x "${D}${INSTALL_DIR}/swarmui_runner.sh"
    if use desktop; then
        insinto /usr/share/applications
        doicon -s 256 "${FILESDIR}/swarmui-web.png"
        doins "${FILESDIR}/swarmui.desktop"
    fi
    cp -f "${FILESDIR}/dotnet-install.sh"  "${D}${INSTALL_DIR}/launchtools/"
    cp -f "${FILESDIR}/linux-build-logic.sh" "${D}${INSTALL_DIR}/launchtools/linux-build-logic.sh"
    cp -f "${FILESDIR}/comfy-install-linux.sh" "${D}${INSTALL_DIR}/launchtools/comfy-install-linux.sh"
    chmod +x "${D}${INSTALL_DIR}/launchtools/dotnet-install.sh"
    chmod +x "${D}${INSTALL_DIR}/launchtools/comfy-install-linux.sh"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}package_version.txt"
    dosym "${INSTALL_DIR}swarmui_runner.sh" "usr/bin/swarmui-web"
    einfo "Example configurations will be stored here: \"${CONFIG_DIR}\"."
    cp -f "${FILESDIR}/env.conf.example" "${D}${CONFIG_DIR}/env.conf.example"
    cd "${D}"
    if use systemd; then
        systemd_newunit "${FILESDIR}"/swarmui.service swarmui.service
    fi
    chown -R genai:genai "${D}${INSTALL_DIR}"
}

pkg_postinst() {
    pkg_config
}

pkg_config() {
    die() { echo "$*" 1>&2 ; exit 1; }
    cd "${INSTALL_DIR}"
    #gpasswd -a genai video
    CHECK_GENAI_UPTODATE=$(groups genai | grep video)
    if [[ -z "${CHECK_GENAI_UPTODATE}" ]]; then
        ewarn ""
        ewarn ""
        ewarn "!!! Please add user genai to group video: \"sudo gpasswd -a genai video\" !!!"
        if use comfyui; then
            ewarn "ComfyUI most probably won't install properly due to this issue, so it is recommended to add user as mentioned above to a group and then re-run installation again."
        fi
        ewarn ""
        ewarn ""
    fi
    elog "Installing dependencies..."
    elog "Installing dotnet."
    sudo -u genai ./launchtools/dotnet-install.sh --channel 8.0 --runtime aspnetcore  || die "Cannot install ASPnetCore"
    sudo -u genai ./launchtools/dotnet-install.sh --channel 8.0 || die "Cannot install Dotnet!"
    if use comfyui; then
        if [ ! -d "dlbackend/ComfyUI" ];then
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
            if use python_single_target_python3_12; then
                PYTHON_EXECUTABLE="python3.12"
            fi
            if use python_single_target_python3_13; then
                PYTHON_EXECUTABLE="python3.13"
            fi
            if use python_single_target_python3_11; then
                PYTHON_EXECUTABLE="python3.11"
            fi
            if use python_single_target_python3_10; then
                PYTHON_EXECUTABLE="python3.10"
            fi
            sudo -u genai ./launchtools/comfy-install-linux.sh "${GPU_TYPE}" "${PYTHON_EXECUTABLE}"
            if use amd_mae; then
                sed -i "/import os/a os.environ\['TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL'\] = '1'" "./dlbackend/ComfyUI/main.py"
                echo "args.use_pytorch_cross_attention = True
" >> ./dlbackend/ComfyUI/comfy/cli_args.py
            fi
            elog "Finished installing ComfyUI."
        else
            elog "ComfyUI already installed, skipping."
        fi
    else
        elog "As You did not select ComfyUI as backend,"
        elog "you will have to manually install/setup the backend."
        elog "Most probably immediately after install SwarmUI won't be able to run."
    fi
    elog "Dependencies installed."
    if use desktop; then
        elog "Registering desktop application."
        update-desktop-database /usr/share/applications
        update-mime-database /usr/share/mime
        xdg_icon_cache_update
        elog "Registering desktop application done."
    fi
	elog "SwarmUI Web App was installed into a virtualenv built into ${INSTALL_DIR}"
	elog ""
	elog "It is run by the user and group genai/genai."
	elog "It may install quite a few dependencies on a first run - expect it to take some time."
	elog "In order to run, please"
	if use systemd; then
	    elog "enable and run the swarmui.service systemd service ( e.g. sudo systemctl enable --now swarmui.service )."
	    elog "Alternatively, you may"
	fi
	elog "run using a user \"genai\" the bash script /usr/bin/swarmui-web ( e.g. sudo -u genai /usr/bin/swarmui-web )."
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
        systemctl stop swarmui.service
        systemctl disable swarmui.service
    fi
    cd "${INSTALL_DIR}"
    rm -rf dlbackend
    rm -f configured
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
