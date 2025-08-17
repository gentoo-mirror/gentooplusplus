#!/bin/bash
INSTALLED_DIR="/var/www/funkwhale"

if [ ! -f "${INSTALLED_DIR}/package_version_init.txt" ]; then
    PACKAGEVERSION=9999
else
    PACKAGEVERSION=`cat ${INSTALLED_DIR}/package_version_init.txt`
fi

FIRST_RUN=0

if [ ! -f "${INSTALLED_DIR}/package_version.txt" ]; then
    PACKAGEVERSIONTEST=9999
else
    PACKAGEVERSIONTEST=`cat ${INSTALLED_DIR}/package_version.txt`
fi
if [[ "${PACKAGEVERSIONTEST}" != "${PACKAGEVERSION}" ]]; then
    FIRST_RUN=1
fi


if [[ $FIRST_RUN -eq 1 ]]; then
SELFSIGNED=0
FUNKWHALE_USER="media"
SERVERHOSTNAME="localhost"
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi
echo    #
read -p "[ INPUT ] Please enter the server address (if empty \"localhost\" will be used): " SERVERHOSTNAME
if [ -z "${SERVERHOSTNAME}" ]; then
    SERVERHOSTNAME="localhost"
fi
echo "[ INFO ] Installing for server \"${SERVERHOSTNAME}\"."
echo    #
echo "[ INFO ] Later in questions please don't press enter after entering Y or y or other symbols."
echo    #
read -p "[ QUESTION ] Would you like to set a password for a media user? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Setting password for a user media."
    passwd media
else
    echo "[ INFO ] Skipping setting up password. If you'd like to do that in the future, use 'passwd media' command."
fi
if [ ! -f "${INSTALLED_DIR}/config/.env" ]; then
    echo "[ INFO ] Configuration didn't exist so copying example configuration. Please don't forget to update it with your data. It is located here: \"${INSTALLED_DIR}/config/.env\""
    cp -f "${INSTALLED_DIR}/config/env.example" "${INSTALLED_DIR}/config/.env"
    sed -i "s,FUNKWHALE_HOSTNAME=localhost,FUNKWHALE_HOSTNAME=${SERVERHOSTNAME}," "${INSTALLED_DIR}/config/.env"
    read -p "[ QUESTION ] Would you like to generate a self-signed certificate)? (type Y or y if yes) " -n 1 -r
    echo    #
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "[ INFO ] Generating a self-signed certificate."
        openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -keyout /etc/ssl/private/localhost.key -out /etc/ssl/certs/localhost.crt -addext "subjectAltName=DNS:${SERVERHOSTNAME}" -subj "/O=The company/CN=${SERVERHOSTNAME}"
        SELFSIGNED=1
    else
        echo "[ INFO ] You will need either to use your own certificate later on or re-generate a self-signed SSL certificate (like this: sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/localhost.key -out /etc/ssl/certs/localhost.crt)."
        echo "[ INFO ] NOT generating a certificate."
    fi
fi
echo "[ INFO ] Setting 600 permissions to the config file ${INSTALLED_DIR}/config/.env."
chmod 777 $INSTALLED_DIR/config/.env
echo "If next command, connected to PostreSQL, fails, this probably means that you have just installed PostgreSQL and you have to configure it. Example - 'emerge --config dev-db/postgresql:17'. After this re-configuration please re-run this script again."
read -p "[ QUESTION ] Would you like to create a funkwhale postresql user? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Creating funkwhale user in postgres."
    sudo -u postgres createuser -P funkwhale
else
    echo "[ INFO ] Skipping setting up postresql database user. If you'd like to do that in the future, use 'sudo -u postgres createuser -P funkwhale' command."
fi
read -p "[ QUESTION ] Would you like to create a funkwhale postresql database? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Dropping database funkwhale if existed."
    sudo -u postgres dropdb -f funkwhale
    echo "[ INFO ] Creating postgres database funkwhale."
    sudo -u postgres createdb -O funkwhale -E UTF8 funkwhale
    echo "[ INFO ] Enabling extensions 'citext' and 'unaccent' in the database."
    sudo -u postgres psql -c "CREATE EXTENSION citext;" funkwhale
    sudo -u postgres psql -c "CREATE EXTENSION unaccent;" funkwhale
else
    echo "[ INFO ] Skipping setting up postresql database user. If you'd like to do that in the future, use '    sudo -u postgres createdb -O funkwhale -E UTF8 funkwhale' command."
fi
cd $INSTALLED_DIR
echo "[ INFO ] Installing dependencies in the virtual python environment."
rm -rf ${INSTALLED_DIR}/venv
sudo -u $FUNKWHALE_USER python3 -m venv ${INSTALLED_DIR}/venv
sudo -u $FUNKWHALE_USER ${INSTALLED_DIR}/venv/bin/pip install --upgrade pip wheel
sudo -u $FUNKWHALE_USER ${INSTALLED_DIR}/venv/bin/pip install --editable ./api
sudo -u $FUNKWHALE_USER ${INSTALLED_DIR}/venv/bin/pip install asgi-lifespan
echo "[ INFO ] Migrating data."
sudo -u $FUNKWHALE_USER ${INSTALLED_DIR}/venv/bin/funkwhale-manage migrate
read -p "[ QUESTION ] Would you like to create a Funkwhale superuser? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Creating a Funkwhale superuser"
    sudo -u $FUNKWHALE_USER ${INSTALLED_DIR}/venv/bin/funkwhale-manage fw users create --superuser
fi
echo "[ INFO ] Collecting static files."
sudo -u $FUNKWHALE_USER ${INSTALLED_DIR}/venv/bin/funkwhale-manage collectstatic
chmod 600 $INSTALLED_DIR/config/.env
chown $FUNKWHALE_USER:$FUNKWHALE_USER $INSTALLED_DIR/config/.env
read -p "[ QUESTION ] Would you like to install the Nginx configuration? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Copying funkwhale nginx config"
    mkdir -p /etc/nginx/sites-available/
    cp ${INSTALLED_DIR}/config/funkwhale_proxy.conf.example /etc/nginx/funkwhale_proxy.conf
    cp ${INSTALLED_DIR}/config/nginx.template.example /etc/nginx/sites-available/funkwhale.template
    set -a && source ${INSTALLED_DIR}/config/.env && set +a
    envsubst "`env | awk -F = '{printf \" $%s\", $$1}'`" \
        < /etc/nginx/sites-available/funkwhale.template \
        > /etc/nginx/sites-available/funkwhale.conf
    sed -i "s,server_name localhost,server_name ${FUNKWHALE_HOSTNAME}," /etc/nginx/sites-available/funkwhale.conf
    if [[ $SELFSIGNED -eq 1 ]]; then
        echo "[ INFO ] Due to self-signed certificate been generated - populating config with a self-signed sertificate"
        sed -i "s,/etc/letsencrypt/live/localhost/privkey.pem,/etc/ssl/private/localhost.key," /etc/nginx/sites-available/funkwhale.conf
        sed -i "s,/etc/letsencrypt/live/localhost/fullchain.pem,/etc/ssl/certs/localhost.crt," /etc/nginx/sites-available/funkwhale.conf
    fi
fi
cd "${INSTALLED_DIR}/front"
echo "[ INFO ] Building frontend (installing yarn)"
sudo -u $FUNKWHALE_USER yarn install
echo "[ INFO ] Building frontend (building itself)"
sudo -u $FUNKWHALE_USER yarn build
cp "${INSTALLED_DIR}/package_version.txt" "${INSTALLED_DIR}/package_version_init.txt"
else
echo "[ INFO ] The package was already initialized. Stopping."
fi
