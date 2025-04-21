# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..12} )

inherit systemd desktop xdg-utils

DESCRIPTION="Stable Diffusion SwarmUI web application"
HOMEPAGE="https://swarmui.net/"
LICENSE="MIT"
SLOT="0"

IUSE="+systemd +desktop python_targets_python3_10  python_targets_python3_11 +python_targets_python3_12" #and docker, later on

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
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/opt/swarmui/"

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
    MY_PV=${PV//_}
    MY_PN="sd-swarmui-web"
    MY_P=${MY_PN}-${MY_PV}
    SRC_URI="https://github.com/mcmonkeyprojects/SwarmUI/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}/"
fi


src_prepare() {
    default
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    mkdir -p "${D}${INSTALL_DIR}/launchtools"
    if use desktop; then
        mkdir -p "${D}/usr/share/applications/"
    fi
    cp -R -f "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    chown -R genai:genai "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/swarmui_runner.sh" "${D}${INSTALL_DIR}"
    chmod +x "${D}${INSTALL_DIR}/swarmui_runner.sh"
    if use desktop; then
        insinto /usr/share/applications
        doicon -s 256 "${FILESDIR}/swarmui-web.png"
        doins "${FILESDIR}/swarmui.desktop"
    fi
    cp -f "${FILESDIR}/dotnet-install.sh"  "${D}${INSTALL_DIR}/launchtools/"
    chmod +x "${D}${INSTALL_DIR}/launchtools/dotnet-install.sh"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}package_version.txt"
    dosym "${INSTALL_DIR}swarmui_runner.sh" "usr/bin/swarmui-web"
    cd "${D}"
    if use systemd; then
        systemd_newunit "${FILESDIR}"/swarmui.service swarmui.service
    fi
}

pkg_postinst() {
    if use desktop; then
        update-desktop-database /usr/share/applications
        update-mime-database /usr/share/mime
        xdg_icon_cache_update
    fi
	elog "SwarmUI Web App was installed into a virtualenv built into ${INSTALL_DIR}"
	elog ""
	elog "It is run by the user and group genai/genai. It will install quite a few dependencies on a first run - expect it to take some time. In order to run, if there is a systemd USE flag used - enable and run the swarmui.service systemd service. Otherwise - please run from a user genai the bash script /usr/bin/swarmui-web."
	elog ""
	elog "Hope it works. Enjoy!"
}

pkg_postrm() {
    if use desktop; then
	    xdg_icon_cache_update
	fi
}
