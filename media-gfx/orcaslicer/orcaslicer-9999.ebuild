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
    sed "s/\&\& groupadd -f -g \$GID \$USER \\\\.*/\#\&\& groupadd -f -g \$GID \$USER \\\\/g" -i "${S}/${MY_P}/Dockerfile" || die
    sed "s/\&\& useradd -u \$UID -g \$GID \$USER.*/\#\&\& useradd -u \$UID -g \$GID \$USER/g" -i "${S}/${MY_P}/Dockerfile" || die
    sed "s/orcaslicer/orcaslicergentoo/" -i "${S}/${MY_P}/DockerRun.sh" || die
    cd "${S}/${MY_P}"
    ./DockerBuild.sh || die
}


src_install() {
    mkdir -p "${D}${INSTALL_DIR}"
    cp -R "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}" || die "Install failed!"
    cp -R "${FILESDIR}/*" "${D}${INSTALL_DIR}"
    dosym "${INSTALL_DIR}orcaslicer_runner.sh" "usr/bin/orcaslicer"
}
