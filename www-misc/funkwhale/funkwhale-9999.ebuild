# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_11 python3_12 python3_13 python3_14 )

inherit systemd

DESCRIPTION="Funkwhale is a self-hosted, modern, free and open-source music server, heavily inspired by Grooveshark."
HOMEPAGE="https://www.funkwhale.audio/"
LICENSE="AGPL-3.0"
SLOT="0"

IUSE="+systemd +nginx apache"

BEPEND="virtual/pkgconfig"

RDEPEND="\
    acct-user/media\
    acct-group/media\
"

DEPEND="\
    ${RDEPEND}\
    media-libs/libjpeg-turbo\
    dev-libs/libpqxx\
    net-libs/libgsasl\
    >=dev-db/postgresql-12.0\
    >=dev-db/redis-6.0\
    >=media-video/ffmpeg-4.3\
    nginx? ( www-servers/nginx[http2,nginx_modules_http_proxy,ssl] )\
    apache? ( www-servers/apache[apache2_modules_proxy,apache2_modules_proxy_http2,apache2_modules_http2,ssl] )\
    dev-perl/File-LibMagic\
    dev-python/python-magic\
    dev-python/ldap3\
    dev-python/python-ldap[sasl]\
    sys-libs/zlib\
    dev-libs/libffi\
    dev-libs/openssl\
    dev-libs/libxml2\
    dev-libs/libxslt\
    dev-python/virtualenv\
    dev-vcs/git\
    net-misc/curl\
    dev-lang/python\
    sys-apps/yarn\
    net-libs/nodejs\
"

DISTUTILS_IN_SOURCE_BUILD=

INSTALL_DIR="/var/www/funkwhale"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://dev.funkwhale.audio/funkwhale/funkwhale"
	EGIT_BRANCH="develop"
	SRC_URI=""
	KEYWORDS=""
    MY_PV=${PV//_}
    MY_P=${PN}-${MY_PV}
    MY_PN="funkwhale"
    S="${WORKDIR}"
else
    MY_PV=${PV//_}
    MY_PN="funkwhale"
    MY_P="funkwhale-${MY_PV}"
    #https://dev.funkwhale.audio/funkwhale/funkwhale/-/archive/1.4.1/funkwhale-1.4.1.tar.gz
    SRC_URI="https://dev.funkwhale.audio/funkwhale/funkwhale/-/archive/${PV}/${MY_PN}-${PV}.tar.gz -> ${P}.gh.tar.gz"
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
    mkdir -p "${D}${INSTALL_DIR}/api"
    mkdir -p "${D}${INSTALL_DIR}/data/static"
    mkdir -p "${D}${INSTALL_DIR}/data/media"
    mkdir -p "${D}${INSTALL_DIR}/data/music"
    mkdir -p "${D}${INSTALL_DIR}/front"
    cp -R -f "${WORKDIR}/${MY_P}/api/." "${D}${INSTALL_DIR}/api/" || die "Install failed (API)!"
    cp -R -f "${WORKDIR}/${MY_P}/front/." "${D}${INSTALL_DIR}/front/" || die "Install failed (front)!"
    cp -f "${WORKDIR}/${MY_P}/deploy/env.prod.sample" "${D}${INSTALL_DIR}/config/env.example"
    cp -f "${WORKDIR}/${MY_P}/deploy/funkwhale_proxy.conf" "${D}${INSTALL_DIR}/config/funkwhale_proxy.conf.example"
    cp -f "${WORKDIR}/${MY_P}/deploy/nginx.template" "${D}${INSTALL_DIR}/config/nginx.template.example"
    cp -f "${WORKDIR}/${MY_P}/deploy/apache.conf" "${D}${INSTALL_DIR}/config/apache.conf.example"
    SECRETKEY=`openssl rand -base64 45`
    sed -i "s,DJANGO_SECRET_KEY=,DJANGO_SECRET_KEY=\"$SECRETKEY\"," "${D}${INSTALL_DIR}/config/env.example"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${INSTALL_DIR}/config/env.example"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${INSTALL_DIR}/config/apache.conf.example"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${INSTALL_DIR}/front/src/ui/components/UploadModal.vue"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${INSTALL_DIR}/api/config/settings/common.py"
    sed -i "s,FUNKWHALE_API_IP=127.0.0.1,FUNKWHALE_API_IP=0.0.0.0," "${D}${INSTALL_DIR}/config/env.example"
    echo "\
DATABASE_URL=postgresql://funkwhale@:5432/funkwhale\
" >> "${D}${INSTALL_DIR}/config/env.example"
    echo "\
CACHE_URL=redis://127.0.0.1:6379/0\
" >> "${D}${INSTALL_DIR}/config/env.example"
    echo "\
REQUESTS_CA_BUNDLE=/etc/ssl/certs/localhost.crt\
" >> "${D}${INSTALL_DIR}/config/env.example"
    sed -i "s,FUNKWHALE_HOSTNAME=yourdomain.funkwhale,FUNKWHALE_HOSTNAME=localhost," "${D}${INSTALL_DIR}/config/env.example"
    sed -i "s,Define funkwhale-sn funkwhale.yourdomain.com, Define funkwhale-sn localhost," "${D}${INSTALL_DIR}/config/apache.conf.example"
    chown -R media:media "${D}${INSTALL_DIR}"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}/package_version.txt"
    if use nginx; then
        cp -f "${FILESDIR}/installer-cli-nginx.sh" funkwhale-installer-cli || die
    elif use apache; then
        cp -f "${FILESDIR}/installer-cli-apache.sh" funkwhale-installer-cli || die
        sed -i "s,REVERSE_PROXY_TYPE=nginx,REVERSE_PROXY_TYPE=apache2," "${D}${INSTALL_DIR}/config/env.example"
    else
        cp -f "${FILESDIR}/installer-cli.sh" funkwhale-installer-cli || die
    fi
    dosbin funkwhale-installer-cli
    chown -R media:media config
    chown -R media:media data
    chown -R media:media "${D}${INSTALL_DIR}"
    cd "${D}"
    keepdir "${INSTALL_DIR}/data/static"
    keepdir "${INSTALL_DIR}/data/media"
    keepdir "${INSTALL_DIR}/data/music"
    if use systemd; then
        systemd_newunit "${FILESDIR}"/funkwhale.target funkwhale.target
        systemd_newunit "${FILESDIR}"/funkwhale-server.service funkwhale-server.service
        systemd_newunit "${FILESDIR}"/funkwhale-worker.service funkwhale-worker.service
        systemd_newunit "${FILESDIR}"/funkwhale-beat.service funkwhale-beat.service
    fi
}

pkg_postinst() {
    elog "Please run funkwhale-installer-cli after this installation in order to complete setup.".
    if use systemd; then
        elog "There are four systemd services installed."
        elog "After the installation script finishes it's work, please perform the following:"
        elog "sudo systemctl daemon-reload"
        elog "sudo systemctl start funkwhale.target"
        elog "sudo systemctl enable --now funkwhale.target"
        elog "Ideally you'd want to reboot after that."
        elog "Alternatively, you may run this:"
        elog "systemctl start funkwhale-worker.service funkwhale-server.service funkwhale-beat.service"
    fi
    if use nginx; then
        elog "After all of that, you probably want to enable the Nginx configuration."
        elog "The easiest way is to perform it like that:"
        elog "sudo ln -s /etc/nginx/sites-available/funkwhale.conf /etc/nginx/funkwhale_vhost.conf"
        elog "Afterwards don't forget to restart nginx."
        if use systemd; then
            elog "systemctl restart nginx"
        else
            elog "rc-service nginx restart"
        fi
    fi
    if use apache; then
        elog "As you decided to use apache, the configutation for this server can be found in here: /etc/apache2/sites-available/funkwhale.conf"
        elog "Just enable this virtualhost."
        elog "Afterwards don't forget to restart apache."
        if use systemd; then
            elog "systemctl restart apache2"
        else
            elog "/etc/init.d/apache2 reload"
        fi
    fi
}
