#!/bin/bash
INSTALLED_DIR="/var/www/peertube"

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


PEERTUBE_USER="media"
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
echo "[ INFO ] Setting 755 permissions to the directory ${INSTALLED_DIR}."
chmod 755 $INSTALLED_DIR
echo "If next command, connected to PostreSQL, fails, this probably means that you have just installed PostgreSQL and you have to configure it. Example - 'emerge --config dev-db/postgresql:17'. After this re-configuration please re-run this script again."
read -p "[ QUESTION ] Would you like to create a peertube postresql user? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Creating peertube user in postgres."
    sudo -u postgres createuser -P peertube
else
    echo "[ INFO ] Skipping setting up postresql database user. If you'd like to do that in the future, use 'sudo -u postgres createuser -P peertube' command."
fi
read -p "[ QUESTION ] Would you like to create a peertube postresql database? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Creating postgres database peertube."
    sudo -u postgres createdb -O peertube -E UTF8 -T template0 peertube_prod
    echo "[ INFO ] Enabling extensions 'pg_trgm' and 'unaccent' in the database."
    sudo -u postgres psql -c "CREATE EXTENSION pg_trgm;" peertube_prod
    sudo -u postgres psql -c "CREATE EXTENSION unaccent;" peertube_prod
else
    echo "[ INFO ] Skipping setting up postresql database user. If you'd like to do that in the future, use '    sudo -u postgres createdb -O peertube -E UTF8 -T template0 peertube_prod' command."
fi
cd $INSTALLED_DIR
sudo -u $PEERTUBE_USER mkdir -p config storage versions
echo "[ INFO ] Setting correct permissions to config direcory."
sudo -u $PEERTUBE_USER chmod 750 config/
cd "${INSTALLED_DIR}/versions"
read -p "[ QUESTION ] Would you like to install the Nginx configuration? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Copying peertube nginx config"
    mkdir -p /etc/nginx/sites-available/
    cp /var/www/peertube/peertube-latest/support/nginx/peertube /etc/nginx/sites-available/peertube
    echo "[ INFO ] You still need to replace the default domain with the one you'd like to use in the file '/etc/nginx/sites-available/peertube'."
    echo "[ INFO ] For example, you may use these commands: "
    echo "  sudo sed -i 's/${WEBSERVER_HOST}/[peertube-domain]/g' /etc/nginx/sites-available/peertube"
    echo "  sudo sed -i 's/${PEERTUBE_HOST}/127.0.0.1:9000/g' /etc/nginx/sites-available/peertube"
    echo "[ INFO ] Don't forget to activate the nginx configuration - for example like this: 'sudo ln -s /etc/nginx/sites-available/peertube /etc/nginx/sites-enabled/peertube'."
fi
cd "${INSTALLED_DIR}"
read -p "[ QUESTION ] Would you like to (re)install npm dependencies just in case? (type Y or y if yes) " -n 1 -r
echo    #
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "[ INFO ] Re-installing node dependencies."
    cd ./peertube-latest && sudo -H -u media npm run install-node-dependencies -- --production
fi
cp "${INSTALLED_DIR}/package_version.txt" "${INSTALLED_DIR}/package_version_init.txt"
else
echo "[ INFO ] The package was already initialized. Stopping."
fi
