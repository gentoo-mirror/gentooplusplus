# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#inherit distutils-r1

DESCRIPTION="Orca Slicer is a free 3D printing slicer created by SoftFever."

HOMEPAGE="https://orca-slicer.com/"

INSTALL_DIR="/opt/orcaslicer/"

if [[ ${PV} == 9999 ]]; then
    EGIT_REPO_URI="https://github.com/SoftFever/OrcaSlicer"
    EGIT_BRANCH="main"
    #EGIT_CHECKOUT_DIR="${S}${INSTALL_DIR}"
    inherit git-r3
    SRC_URI=""
    KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="orcaslicer"
    S="${WORKDIR}"
else
    MY_PV=${PV//_}
    MY_PN="OrcaSlicer"
    MY_P=${MY_PN}-${MY_PV}
    SRC_URI="https://github.com/SoftFever/OrcaSlicer/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"
    KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}"
fi

LICENSE="GPL-3"

SLOT="0"

DEPEND="
    app-containers/docker-cli
    app-containers/docker
"

RDEPEND="${DEPEND}"

BDEPEND=""

src_prepare() {
    default
    sed "s/FROM docker\.io\/ubuntu\:.*/FROM docker\.io\/ubuntu\:22\.04/g" -i "${S}/${MY_P}/Dockerfile" || die
    sed "s/RUN \[\[ \"\$UID\" \!\= \"0\" \]\] \\\\.*/\# RUN \[\[ \"\$UID\" \!\= \"0\" \]\]  \\\\/g" -i "${S}/${MY_P}/Dockerfile" || die
    sed "s/groupadd -f -g \$GID \$USER; \\\\.*/\#groupadd -f -g \$GID \$USER; \\\\/g" -i "${S}/${MY_P}/Dockerfile" || die
    sed "s/useradd -u \$UID -g \$GID \$USER; \\\\.*/\echo ; \\\\/g" -i "${S}/${MY_P}/Dockerfile" || die
    sed "s/orcaslicer/orcaslicergentoo/" -i "${S}/${MY_P}/DockerRun.sh" || die
    sed "s/\-ti/\-dit/" -i "${S}/${MY_P}/DockerRun.sh" || die
    cd "${S}/${MY_P}"
    die() { echo "$*" 1>&2 ; exit 1; }
    ./DockerBuild.sh || die " [ ERROR ] Could not build docker. Please check if portage user is in docker group. If not, please add, then re-run, smth like this: sudo usermod -aG docker portage"
}


src_install() {
    mkdir -p "${D}${INSTALL_DIR}"
    mkdir -p "${D}/usr/share/icons/hicolor/192x192/apps/"
    mkdir -p "${D}/usr/share/applications/"
    cp -R -f "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    cp -f "${FILESDIR}/orcaslicer_runner.sh" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/Dockerfile2" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/DockerBuild2.sh" "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/OrcaSlicer.png" "${D}/usr/share/icons/hicolor/192x192/apps/"
    cp -f "${FILESDIR}/orcaslicer.desktop" "${D}/usr/share/applications/"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}package_version.txt"
    dosym "${INSTALL_DIR}orcaslicer_runner.sh" "usr/bin/orcaslicer"
}
