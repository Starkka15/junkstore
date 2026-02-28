#!/usr/bin/env bash
ITCHIOCONF="${DECKY_PLUGIN_DIR}/scripts/itchio-config.py"
export PYTHONPATH="${DECKY_PLUGIN_DIR}/scripts/":"${DECKY_PLUGIN_DIR}/scripts/shared/":$PYTHONPATH

export LAUNCHER="${DECKY_PLUGIN_DIR}/scripts/${Extensions}/Itchio/itchio-launcher.sh"
export ARGS_SCRIPT="${DECKY_PLUGIN_DIR}/scripts/${Extensions}/Itchio/get-itchio-args.sh"

DBNAME="itchio.db"
DBFILE="${DECKY_PLUGIN_RUNTIME_DIR}/itchio.db"

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/itchiotabconfig.json" ]]; then
    TEMP="${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/itchiotabconfig.json"
else
    TEMP="${DECKY_PLUGIN_DIR}/conf_schemas/itchiotabconfig.json"
fi
SETTINGS=$($ITCHIOCONF --generate-env-settings-json $TEMP --dbfile $DBFILE 2>/dev/null) || true
eval "${SETTINGS}" 2>/dev/null || true

if [[ "${ITCHIO_INSTALLLOCATION}" == "SSD" ]]; then
    INSTALL_DIR="${HOME}/Games/itchio/"
elif [[ "${ITCHIO_INSTALLLOCATION}" == "MicroSD" ]]; then
    NVME=$(lsblk --list | grep nvme0n1\ |awk '{ print $2}' |  awk '{split($0, a,":"); print a[1]}')
    LINK=$(find /run/media -maxdepth 1  -type l )
    LINK_TARGET=$(readlink -f "${LINK}")
    MOUNT_POINT=$(lsblk --list --exclude "${NVME}" | grep part |  sed -n 's/.*part //p')
    if [[ "${MOUNT_POINT}" == "${LINK_TARGET}" ]]; then
        INSTALL_DIR="${LINK}/Games/itchio/"
    else
        INSTALL_DIR="/run/media/mmcblk0p1/Games/itchio/"
    fi
else
    INSTALL_DIR="${HOME}/Games/"
fi

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/itchio_overrides.sh" ]]; then
   source "${DECKY_PLUGIN_RUNTIME_DIR}/itchio_overrides.sh"
fi

export INSTALL_DIR
