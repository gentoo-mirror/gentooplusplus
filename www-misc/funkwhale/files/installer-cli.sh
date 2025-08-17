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
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi
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
    read -p "[ QUESTION ] Would you like to generate a self-signed certificate)? (type Y or y if yes) " -n 1 -r
    echo    #
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "[ INFO ] Generating a self-signed certificate."
        openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -keyout /etc/ssl/private/localhost.key -out /etc/ssl/certs/localhost.crt -addext "subjectAltName=DNS:localhost" -subj "/O=The company/CN=localhost"
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
cd "${INSTALLED_DIR}/front"
echo "[ INFO ] Building frontend (installing yarn)"
sudo -u $FUNKWHALE_USER yarn install
echo "[ INFO ] Building frontend (building itself)"
sudo -u $FUNKWHALE_USER yarn build
cp "${INSTALLED_DIR}/package_version.txt" "${INSTALLED_DIR}/package_version_init.txt"
else
echo "[ INFO ] The package was already initialized. Stopping."
fi
