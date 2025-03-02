#!/bin/bash

if [ ! -f /opt/orcaslicer/package_version.txt ]; then
    PACKAGEVERSION=9999
else
    PACKAGEVERSION=`cat /opt/orcaslicer/package_version.txt`
fi

FIRST_RUN=0

if [ ! -f ~/.config/orcaslicer/configured ]; then
    FIRST_RUN=1
else
    if [ ! -f /opt/orcaslicer/package_version.txt ]; then
        PACKAGEVERSIONTEST=9999
    else
        PACKAGEVERSIONTEST=`cat /opt/orcaslicer/package_version.txt`
    fi
    if [[ $PACKAGEVERSIONTEST -ne $PACKAGEVERSION ]]; then
        FIRST_RUN=1
    fi
fi


if [[ $FIRST_RUN -eq 1 ]]; then
    mkdir -p ~/.config/orcaslicer/
    touch ~/.config/orcaslicer/configured
    cat /opt/orcaslicer/package_version.txt > ~/.config/orcaslicer/configured
    /opt/orcaslicer/DockerBuild2.sh
fi

RES=1

/opt/orcaslicer/DockerRun.sh || RES=0
if [[ $RES -eq 0 ]]; then
#    if [[ $PACKAGEVERSION -eq 9999 ]]; then
        echo ""
        echo ""
        echo "[ ERROR ] If you have just reinstalled the package, please remove the file ~/.config/orcaslicer/configured and restart program. Or some other error happened."
        echo ""
        echo ""

#    fi
fi
