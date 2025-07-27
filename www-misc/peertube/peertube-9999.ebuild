# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_12 python3_13 )

#inherit systemd

DESCRIPTION="PeerTube is a free, decentralized and federated video platform developed as an alternative to other platforms that centralize our data and attention, such as YouTube, Dailymotion or Vimeo."
HOMEPAGE="https://joinpeertube.org/"
LICENSE="AGPL-3.0"
SLOT="0"

IUSE=""

BEPEND="virtual/pkgconfig"

RDEPEND="\
    acct-user/media\
    acct-group/media\
"

DEPEND="\
    ${RDEPEND}\
    >=net-libs/nodejs-20.9[npm]\
    <sys-apps/yarn-2.0\
    >=sys-apps/yarn-1.0\
    >=dev-db/postgresql-10.0\
    >=dev-db/redis-6.0\
    >=media-video/ffmpeg-4.3[x264]\
    dev-python/virtualenv\
    dev-vcs/git\
    net-misc/curl\
    app-arch/unzip\
    dev-lang/python\
    dev-lang/python-exec\
    www-servers/nginx[threads,aio]\
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/var/www/peertube"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/chocobozzz/peertube"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="peertube"
    S="${WORKDIR}"
else
    MY_PV=${PV//_}
    MY_PN="peertube"
    MY_P="peertube-v${MY_PV}"
    SRC_URI="https://github.com/Chocobozzz/PeerTube/releases/download/v${PV}/${MY_PN}-v${PV}.tar.xz -> ${P}.gh.tar.xz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
    S="${WORKDIR}/"
fi


src_prepare() {
    default
}

src_install() {
    die() { echo "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    mkdir -p "${D}${INSTALL_DIR}/config"
    mkdir -p "${D}${INSTALL_DIR}/storage"
    mkdir -p "${D}${INSTALL_DIR}/versions"
    mkdir -p "${D}${INSTALL_DIR}/versions/${PV}"
    mkdir -p "${D}etc/nginx/sites-available"
    cp -R -f "${WORKDIR}/${MY_P}/." "${D}${INSTALL_DIR}/versions/${PV}/" || die "Install failed!"
    chown -R media:media "${D}${INSTALL_DIR}"
    cp -f "${FILESDIR}/installer-cli.sh" "${D}${INSTALL_DIR}/"
    chmod +x "${D}${INSTALL_DIR}/installer-cli.sh"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}/package_version.txt"
    dosym "${INSTALL_DIR}/versions/${PV}" "var/www/peertube/peertube-latest"
    cp -f "${FILESDIR}/installer-cli.sh" peertube-installer-cli || die
    dosbin peertube-installer-cli
    cd "${D}${INSTALL_DIR}/peertube-latest"
    npm run install-node-dependencies -- --production
    cd "${D}${INSTALL_DIR}"
    cp "${D}${INSTALL_DIR}/versions/${PV}/config/default.yaml" config/default.yaml
    cp "${D}${INSTALL_DIR}/versions/${PV}peertube-latest/config/production.yaml.example" config/production.yaml
    chown -R media:media config
    chown -R media:media "${D}${INSTALL_DIR}"
    cd "${D}"
}
