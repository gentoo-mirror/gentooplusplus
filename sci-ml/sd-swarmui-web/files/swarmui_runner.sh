#!/bin/sh

die() { echo "$*" 1>&2 ; exit 1; }
HOME=/opt/swarmui/
cd /opt/swarmui/

if [ ! -f /opt/swarmui/package_version.txt ]; then
    PACKAGEVERSION=9999
else
    PACKAGEVERSION=`cat /opt/swarmui/package_version.txt`
fi

FIRST_RUN=0

if [ ! -f /opt/swarmui/configured ]; then
    FIRST_RUN=1
else
    if [ ! -f /opt/swarmui/package_version.txt ]; then
        PACKAGEVERSIONTEST=9999
    else
        PACKAGEVERSIONTEST=`cat /opt/swarmui/configured`
    fi
    if [[ $PACKAGEVERSIONTEST -ne $PACKAGEVERSION ]]; then
        FIRST_RUN=1
    fi
fi



if [[ $FIRST_RUN -eq 1 ]]; then
    cat /opt/swarmui/package_version.txt > /opt/swarmui/configured
    # FIRST RUN ACTIONS
    echo "First run - installing dependencies."
    ./launchtools/dotnet-install.sh --channel 8.0 --runtime aspnetcore  || die "Cannot install ASPnetCore"
    ./launchtools/dotnet-install.sh --channel 8.0 || die "Cannot install Dotnet!"
    echo "Dependencies installed."
    touch /opt/swarmui/configured
fi

./launch-linux.sh --launch_mode none
# --port 7801 --host 0.0.0.0
