# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_10 python3_11 )

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
CONFIG_DIR="/etc/funkwhale"

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
    die() { eerror "$*" 1>&2 ; exit 1; }
    mkdir -p "${D}${INSTALL_DIR}"
    mkdir -p "${D}${CONFIG_DIR}"
    #mkdir -p "${D}${INSTALL_DIR}/config"
    mkdir -p "${D}${INSTALL_DIR}/api"
    mkdir -p "${D}${INSTALL_DIR}/data/static"
    mkdir -p "${D}${INSTALL_DIR}/data/media"
    mkdir -p "${D}${INSTALL_DIR}/data/music"
    mkdir -p "${D}${INSTALL_DIR}/front"
    cp -R -f "${WORKDIR}/${MY_P}/api/." "${D}${INSTALL_DIR}/api/" || die "Install failed (API)!"
    cp -R -f "${WORKDIR}/${MY_P}/front/." "${D}${INSTALL_DIR}/front/" || die "Install failed (front)!"
    einfo "Example configurations will be stored here: \"${CONFIG_DIR}\"."
    cp -f "${WORKDIR}/${MY_P}/deploy/env.prod.sample" "${D}${CONFIG_DIR}/env.example"
    cp -f "${WORKDIR}/${MY_P}/deploy/funkwhale_proxy.conf" "${D}${CONFIG_DIR}/funkwhale_proxy.conf.example"
    cp -f "${WORKDIR}/${MY_P}/deploy/nginx.template" "${D}${CONFIG_DIR}/nginx.template.example"
    cp -f "${WORKDIR}/${MY_P}/deploy/apache.conf" "${D}${CONFIG_DIR}/apache.conf.example"
    dosym "${CONFIG_DIR}" "${INSTALL_DIR}/config"
    SECRETKEY=`openssl rand -base64 45`
    if [[ ${PV} != 9999 ]]; then
        sed -i "s,django-allauth = \"==0.42.0\",django-allauth = \"==0.50.0\"," "${D}${INSTALL_DIR}/api/pyproject.toml"
    fi
    elog "A base64 secret key was generated and stored in the example config file \"${CONFIG_DIR}/env.example\"."
    sed -i "s,DJANGO_SECRET_KEY=,DJANGO_SECRET_KEY=\"$SECRETKEY\"," "${D}${CONFIG_DIR}/env.example"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${CONFIG_DIR}/env.example"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${CONFIG_DIR}/apache.conf.example"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${INSTALL_DIR}/front/src/ui/components/UploadModal.vue"
    sed -i "s,/srv/funkwhale,${INSTALL_DIR}," "${D}${INSTALL_DIR}/api/config/settings/common.py"
    elog "Please pay attention to the fact that the example config file allows the wordwide access to the Funkwhale (FUNKWHALE_API_IP is set to \"0.0.0.0\" in the file \"${CONFIG_DIR}/env.example\")."
    sed -i "s,FUNKWHALE_API_IP=127.0.0.1,FUNKWHALE_API_IP=0.0.0.0," "${D}${CONFIG_DIR}/env.example"
    echo "\
DATABASE_URL=postgresql://funkwhale@:5432/funkwhale\
" >> "${D}${CONFIG_DIR}/env.example"
    echo "\
CACHE_URL=redis://127.0.0.1:6379/0\
" >> "${D}${CONFIG_DIR}/env.example"
    echo "\
REQUESTS_CA_BUNDLE=/etc/ssl/certs/localhost.crt\
" >> "${D}${CONFIG_DIR}/env.example"
    elog "The example config \"${CONFIG_DIR}/env.example\" assumes that Redis is up and running and is passwordless, uses standard port 6379 and works locally."
    elog "The example config \"${CONFIG_DIR}/env.example\" assumes that Postgres is also running locally and uses standard port 5432."
    elog "It that's not the case - please don't forget to adjust settings accordingly."
    sed -i "s,FUNKWHALE_HOSTNAME=yourdomain.funkwhale,FUNKWHALE_HOSTNAME=localhost," "${D}${CONFIG_DIR}/env.example"
    sed -i "s,Define funkwhale-sn funkwhale.yourdomain.com, Define funkwhale-sn localhost," "${D}${CONFIG_DIR}/apache.conf.example"
    chown -R media:media "${D}${INSTALL_DIR}"
    echo "${PV}-${RANDOM}" > "${D}${INSTALL_DIR}/package_version.txt"
    PYTHON_EXECUTABLE="python3"
    if [[ ${PV} == 9999 ]]; then
        PYTHON_EXECUTABLE="python3"
    else
        if ! command -v python3.11 >/dev/null 2>&1
        then
            PYTHON_EXECUTABLE="python3.10"
        else
            PYTHON_EXECUTABLE="python3.11"
        fi
    fi
    if use nginx; then
        cp -f "${FILESDIR}/installer-cli-nginx.sh" funkwhale-installer-cli || die
    elif use apache; then
        cp -f "${FILESDIR}/installer-cli-apache.sh" funkwhale-installer-cli || die
        sed -i "s,REVERSE_PROXY_TYPE=nginx,REVERSE_PROXY_TYPE=apache2," "${D}${CONFIG_DIR}/env.example"
    else
        cp -f "${FILESDIR}/installer-cli.sh" funkwhale-installer-cli || die
    fi
    if [[ ${PV} != 9999 ]]; then
        sed -i "s,python3,${PYTHON_EXECUTABLE}," funkwhale-installer-cli
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
    elog ""
    elog ""
    elog ""
    elog " [!!!] Package installed, now it has to be configured. [!!!] "
    elog ""
    #if [[ ${PV} == 9999 ]]; then
    elog "You can do it by running \"emerge --config www-misc/funkwhale\" "
    #else
    #    elog "You can do it by running \"emerge --config www-misc/funkwhale:${PV}\" "
    #fi
    elog ""
    elog ""
    elog ""
    elog "...or do the following (if manual way is preferred):"
    elog "run funkwhale-installer-cli after this installation in order to complete setup."
    if use systemd; then
        elog "[Systemd] related:"
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
        elog "[Nginx] related:"
        elog "After all of that, you probably want to enable the Nginx configuration."
        elog "The easiest way is to perform it like that:"
        elog "sudo ln -s ${EROOT}/etc/nginx/sites-available/funkwhale.conf ${EROOT}/etc/nginx/funkwhale_vhost.conf"
        elog "Afterwards don't forget to restart nginx."
        if use systemd; then
            elog "systemctl restart nginx"
        else
            elog "rc-service nginx restart"
        fi
    fi
    if use apache; then
        elog "[Apache] related:"
        elog "As you decided to use apache, the configutation for this server can be found in here: ${EROOT}/etc/apache2/sites-available/funkwhale.conf"
        elog "Just enable this virtualhost."
        elog "Afterwards don't forget to restart apache."
        if use systemd; then
            elog "systemctl restart apache2"
        else
            elog "/etc/init.d/apache2 reload"
        fi
    fi
}

pkg_config() {
    if [[ -f "${EROOT}${INSTALL_DIR}/package_version_init.txt" ]]; then
        PACKAGEVERSION=`cat ${EROOT}${INSTALL_DIR}/package_version_init.txt`
        PACKAGEVERSIONTEST=`cat ${EROOT}${INSTALL_DIR}/package_version.txt`
        if [[ "${PACKAGEVERSIONTEST}" != "${PACKAGEVERSION}" ]]; then
            if [[ ${PV} == 9999 ]]; then
                einfo "Package was already configured for a different version - most probably it was reinstalled."
            else
                einfo "Package was already configured for a different version - looks like it is an upgrade or reinstall."
            fi
        else
            einfo "Package is already configured for this exact version. Please confirm you want to reconfigure it."
        fi
        einfo "If you don't want to re-configure, please press Ctrl+C now."
        einfo "Otherwise, press Enter."
        read
        einfo "Performing re-configuration."
        rm -f "${EROOT}${INSTALL_DIR}/package_version_init.txt"
        cd "${EROOT}${INSTALL_DIR}"
        if use systemd; then
            einfo "Stopping systemd service."
            systemctl daemon-reload
            systemctl stop funkwhale.target
        fi
        einfo "Cleaning up."
        rm -Rf api/* front/* venv
    else
        einfo "This will start the configuration phase."
        einfo "Press Enter to continue or Ctrl+C to cancel."
        read
        einfo "Performing configuration."
    fi
    cd "${EROOT}${INSTALL_DIR}"
    einfo "Running installer."
    funkwhale-installer-cli
    if use systemd; then
        einfo "Enabling systemd services..."
        systemctl daemon-reload
        systemctl start funkwhale.target
        systemctl enable --now funkwhale.target
        einfo "Finished with systemd services."
        einfo "Ideally you'd want to reboot after that."
        einfo "Alternatively, you may run this if the services appear to be not running:"
        einfo "systemctl start funkwhale-worker.service funkwhale-server.service funkwhale-beat.service"
    fi
    if use nginx; then
        ln -sf "${EROOT}/etc/nginx/sites-available/funkwhale.conf" "${EROOT}/etc/nginx/funkwhale_vhost.conf"
        einfo "Don't forget to restart nginx after checking it's configuration, like this:"
        if use systemd; then
            einfo "systemctl restart nginx"
        else
            einfo "rc-service nginx restart"
        fi
    fi
    if use apache; then
        einfo "The Apache configutation for this server can be found in here: ${EROOT}/etc/apache2/sites-available/funkwhale.conf"
        einfo "Just enable this virtualhost."
        einfo "Afterwards don't forget to restart apache, like this:"
        if use systemd; then
            einfo "systemctl restart apache2"
        else
            einfo "/etc/init.d/apache2 reload"
        fi
    fi
    einfo "Configuration finished."
}

pkg_prerm() {
    if use systemd; then
        einfo "Stopping systemd services."
        systemctl daemon-reload
        systemctl stop funkwhale.target
        systemctl disable funkwhale.target
    fi
    if use nginx; then
        einfo "Removing Nginx templates."
        [[ -e "${EROOT}/etc/nginx/funkwhale_vhost.conf" ]] && rm -f "${EROOT}/etc/nginx/funkwhale_vhost.conf"
        [[ -e "${EROOT}/etc/nginx/funkwhale_proxy.conf" ]] && rm -f "${EROOT}/etc/nginx/funkwhale_proxy.conf"
        [[ -e "${EROOT}/etc/nginx/sites-available/funkwhale.template" ]] && rm -f "${EROOT}/etc/nginx/sites-available/funkwhale.template"
    fi
    einfo "Removing virtual environment and static files."
    [[ -f "${EROOT}/usr/sbin/funkwhale-installer-cli" ]] && rm -f "${EROOT}/usr/sbin/funkwhale-installer-cli"
    [[ -d "${EROOT}${INSTALL_DIR}/venv" ]] && rm -rf "${EROOT}${INSTALL_DIR}/venv"
    [[ -d "${EROOT}${INSTALL_DIR}/front" ]] && rm -rf "${EROOT}${INSTALL_DIR}/front"
    [[ -d "${EROOT}${INSTALL_DIR}/api" ]] && rm -rf "${EROOT}${INSTALL_DIR}/api"
    [[ -d "${EROOT}${INSTALL_DIR}/data/static" ]] && rm -rf "${EROOT}${INSTALL_DIR}/data/static"
    [[ -f "${EROOT}${INSTALL_DIR}/package_version_init.txt" ]] && rm -f "${EROOT}${INSTALL_DIR}/package_version_init.txt"
}

pkg_postrm() {
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
    if use nginx; then
        ewarn ""
        ewarn "Please don't forget to reload nginx manually after this uninstallation."
        ewarn ""
    fi
}
