#!/bin/sh

die() { echo "$*" 1>&2 ; exit 1; }
HOME=/opt/kohyas_gui/
STARTUP_CMD="python3.12"
cd /opt/kohyas_gui/

if [ ! -f /opt/kohyas_gui/package_version.txt ]; then
    PACKAGEVERSION=9999
else
    PACKAGEVERSION=`cat /opt/kohyas_gui/package_version.txt`
fi

FIRST_RUN=0

if [ ! -f /opt/kohyas_gui/configured ]; then
    FIRST_RUN=1
else
    if [ ! -f /opt/kohyas_gui/package_version.txt ]; then
        PACKAGEVERSIONTEST=9999
    else
        PACKAGEVERSIONTEST=`cat /opt/kohyas_gui/configured`
    fi
    if [ "$PACKAGEVERSIONTEST" != "$PACKAGEVERSION" ]; then
        FIRST_RUN=1
    fi
fi



if [[ $FIRST_RUN -eq 1 ]]; then
    cat /opt/kohyas_gui/package_version.txt > /opt/kohyas_gui/configured
    # FIRST RUN ACTIONS
    echo "First run - installing dependencies."
    ./gentoo_installer.sh
    echo "Dependencies installed."
    touch /opt/kohyas_gui/configured
fi
# default port 7860
./gui.sh --listen=0.0.0.0 --headless
