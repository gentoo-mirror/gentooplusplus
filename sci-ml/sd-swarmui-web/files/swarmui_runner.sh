#!/bin/bash

die() { echo "$*" 1>&2 ; exit 1; }
#HOME=/opt/swarmui/
CONFIG_FILE="/etc/swarmui/env.conf"
export PATH="${PATH}:/opt/genai/.dotnet:/opt/swarmui/.dotnet:/opt/cuda/bin/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/cuda/lib64/"
export PKG_CONFIG_PATH="/opt/cuda/pkgconfig"
export CUDA_HOME="/opt/cuda/"

cd /opt/swarmui/

if [ ! -f /opt/swarmui/package_version.txt ]; then
    PACKAGEVERSION=9999
else
    PACKAGEVERSION=`cat /opt/swarmui/package_version.txt`
fi

FIRST_RUN="0"

if [ ! -f /opt/swarmui/configured ]; then
    FIRST_RUN="1"
else
    if [ ! -f /opt/swarmui/package_version.txt ]; then
        PACKAGEVERSIONTEST=9999
    else
        PACKAGEVERSIONTEST=`cat /opt/swarmui/configured`
    fi
    if [[ "${PACKAGEVERSIONTEST}" != "${PACKAGEVERSION}" ]]; then
        FIRST_RUN="1"
    fi
fi



if [[ "${FIRST_RUN}" == "1" ]]; then
    cat /opt/swarmui/package_version.txt > /opt/swarmui/configured
#    # FIRST RUN ACTIONS
#    echo "First run - installing dependencies."
#    ./launchtools/dotnet-install.sh --channel 8.0 --runtime aspnetcore  || die "Cannot install ASPnetCore"
#    ./launchtools/dotnet-install.sh --channel 8.0 || die "Cannot install Dotnet!"
#    echo "Dependencies installed."
    touch /opt/swarmui/configured
    # To force rebuild if new install or update
    mkdir -p /opt/swarmui/src/bin/
    touch /opt/swarmui/src/bin/must_rebuild
fi

if [ ! -e "${CONFIG_FILE}" ]; then
    ./launch-linux.sh --launch_mode none
else
    RUN_STR=""
    SWARMUI_LAUNCH_MODE="-"
    SWARMUI_HOST="-"
    SWARMUI_PORT="-"
    SWARMUI_USERID="-"
    SWARMUI_ASPLOGLEVEL="-"
    SWARMUI_LOGLEVEL="-"
    SWARMUI_SETTINGS="-"
    # true/false
    SWARMUI_LOCKSETTINGS="-"
    SWARMUI_DATADIR="-"
    SWARMUI_BACKENDSFILE="-"
    SWARMUI_NGROK_PATH="-"
    SWARMUI_NGROK_BASIC_AUTH="-"
    SWARMUI_CLOUDFLARED_PATH="-"
    SWARMUI_PROXY_REGION="-"
    SWARMUI_PROXY_ADDED_ARGS="-"
    # Production/Development
    SWARMUI_ENVIRONMENT="-"
    SWARMUI_EXTRA="-"
    source "${CONFIG_FILE}"
    if [ "${SWARMUI_LAUNCH_MODE}" != "-" ]; then
        RUN_STR="${RUN_STR} --launch_mode ${SWARMUI_LAUNCH_MODE}"
    else
        RUN_STR="${RUN_STR} --launch_mode none"
    fi
    if [ "${SWARMUI_HOST}" != "-" ]; then
        RUN_STR="${RUN_STR} --host ${SWARMUI_HOST}"
    fi
    if [ "${SWARMUI_PORT}" != "-" ]; then
        RUN_STR="${RUN_STR} --port ${SWARMUI_PORT}"
    fi
    if [ "${SWARMUI_USERID}" != "-" ]; then
        RUN_STR="${RUN_STR} --user_id ${SWARMUI_USERID}"
    fi
    if [ "${SWARMUI_ASPLOGLEVEL}" != "-" ]; then
        RUN_STR="${RUN_STR} --asp_loglevel ${SWARMUI_ASPLOGLEVEL}"
    fi
    if [ "${SWARMUI_LOGLEVEL}" != "-" ]; then
        RUN_STR="${RUN_STR} --loglevel ${SWARMUI_LOGLEVEL}"
    fi
    if [ "${SWARMUI_SETTINGS}" != "-" ]; then
        RUN_STR="${RUN_STR} --settings_file ${SWARMUI_SETTINGS}"
    fi
    if [ "${SWARMUI_LOCKSETTINGS}" != "-" ]; then
        RUN_STR="${RUN_STR} --lock_settings ${SWARMUI_LOCKSETTINGS}"
    fi
    if [ "${SWARMUI_DATADIR}" != "-" ]; then
        RUN_STR="${RUN_STR} --data_dir \"${SWARMUI_DATADIR}\""
    fi
    if [ "${SWARMUI_BACKENDSFILE}" != "-" ]; then
        RUN_STR="${RUN_STR} --backends_file ${SWARMUI_BACKENDSFILE}"
    fi
    if [ "${SWARMUI_NGROK_PATH}" != "-" ]; then
        RUN_STR="${RUN_STR} --ngrok-path \"${SWARMUI_NGROK_PATH}\""
    fi
    if [ "${SWARMUI_NGROK_BASIC_AUTH}" != "-" ]; then
        RUN_STR="${RUN_STR} --ngrok-basic-auth \"${SWARMUI_NGROK_BASIC_AUTH}\""
    fi
    if [ "${SWARMUI_CLOUDFLARED_PATH}" != "-" ]; then
        RUN_STR="${RUN_STR} --cloudflared-path \"${SWARMUI_CLOUDFLARED_PATH}\""
    fi
    if [ "${SWARMUI_PROXY_REGION}" != "-" ]; then
        RUN_STR="${RUN_STR} --proxy-region ${SWARMUI_PROXY_REGION}"
    fi
    if [ "${SWARMUI_PROXY_ADDED_ARGS}" != "-" ]; then
        RUN_STR="${RUN_STR} --proxy-added-args ${SWARMUI_PROXY_ADDED_ARGS}"
    fi
    if [ "${SWARMUI_ENVIRONMENT}" != "-" ]; then
        RUN_STR="${RUN_STR} --environment ${SWARMUI_ENVIRONMENT}"
    fi
    if [ "${SWARMUI_EXTRA}" != "-" ]; then
        RUN_STR="${RUN_STR} ${SWARMUI_EXTRA}"
    fi
    if [ -e "Data/Settings.fds" ]; then
        sed -i 's,OverrideWelcomeMessage: \\x,OverrideWelcomeMessage: <h2>Welcome to SwarmUI - Stable Diffusion generator.<\/h2> <p>General config file is located here: \/etc\/swarmui\/env.conf<\/p>,' "Data/Settings.fds"
        sed -i 's,CheckForUpdates: true,CheckForUpdates: false,' "Data/Settings.fds"
    fi
    bash -c "./launch-linux.sh ${RUN_STR}"
fi
