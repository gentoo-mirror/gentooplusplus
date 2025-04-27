# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_12 )

inherit systemd desktop xdg-utils

DESCRIPTION="Kohya's GUI Web application"
HOMEPAGE="https://github.com/bmaltais/kohya_ss"
LICENSE="Apache-2.0"
SLOT="0"

IUSE="+systemd +desktop +python_targets_python3_12"

BEPEND="virtual/pkgconfig"

RDEPEND="\
    acct-user/genai\
    acct-group/genai\
"

DEPEND="\
    ${RDEPEND}\
    dev-python/virtualenv\
    dev-vcs/git\
    net-misc/curl\
    net-misc/wget\
    dev-lang/python[tk]\
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/opt/kohyas_gui/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/Eugeniusz-Gienek/kohya_gui"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="kohyas-gui"
    S="${WORKDIR}"
else
    MY_PV=${PV//_}
    MY_PN="kohyas-gui"
    MY_P="kohya_gui-"${MY_PV}
    SRC_URI="https://github.com/Eugeniusz-Gienek/kohya_gui/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}/"
fi


src_prepare() {
    default
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    if use desktop; then
        mkdir -p "${D}/usr/share/applications/"
    fi
    cp -R -f "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    chown -R genai:genai "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/kohyas_gui_runner.sh" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/gentoo_installer.sh" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/requirements_linux_gentoo.txt" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/git.tar.gz" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/gentoo.yaml" "${D}${INSTALL_DIR}config_files/accelerate/"
    chmod +x "${D}${INSTALL_DIR}/kohyas_gui_runner.sh"
    chmod +x "${D}${INSTALL_DIR}/gentoo_installer.sh"
    if use desktop; then
        insinto /usr/share/applications
        doicon -s 256 "${FILESDIR}/kohyas-gui-web.png"
        doins "${FILESDIR}/kohyas_gui.desktop"
    fi
    #cp -f "${FILESDIR}/dotnet-install.sh"  "${D}${INSTALL_DIR}/launchtools/"
    #chmod +x "${D}${INSTALL_DIR}/launchtools/dotnet-install.sh"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}package_version.txt"
    dosym "${INSTALL_DIR}kohyas_gui_runner.sh" "usr/bin/kohyas-gui-web"
    cd "${D}"
    if use systemd; then
        systemd_newunit "${FILESDIR}"/kohyas_gui.service kohyas-gui.service
    fi
    cd "${D}${INSTALL_DIR}"
    tar -xf git.tar.gz
    chown -R genai:genai "${D}${INSTALL_DIR}.git"
    rm git.tar.gz
}

pkg_postinst() {
    if use desktop; then
        update-desktop-database /usr/share/applications
        update-mime-database /usr/share/mime
        xdg_icon_cache_update
    fi
	elog "Kohya's GUI Web App was installed into a virtualenv built into ${INSTALL_DIR}"
	elog ""
	elog "It is run by the user and group genai/genai. It will install quite a few dependencies on a first run - expect it to take some time. In order to run, if there is a systemd USE flag used - enable and run the kohyas-gui.service systemd service. Otherwise - please run from a user genai the bash script /usr/bin/kohyas-gui-web."
	elog ""
	elog "Hope it works. Enjoy!"
}

pkg_postrm() {
    if use desktop; then
	    xdg_icon_cache_update
	fi
}
