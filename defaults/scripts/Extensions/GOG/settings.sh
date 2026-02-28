#!/usr/bin/env bash
GOGCONF="${DECKY_PLUGIN_DIR}/scripts/gog-config.py"
# lgogdownloader (flatpak)
export LGOGDL="/bin/flatpak run com.github.sude_.lgogdownloader"
# gogdl (flatpak)
export GOGDL="/bin/flatpak run com.github.heroic_games_launcher.heroic-gogdl"
export PYTHONPATH="${DECKY_PLUGIN_DIR}/scripts/":"${DECKY_PLUGIN_DIR}/scripts/shared/":$PYTHONPATH

export LAUNCHER="${DECKY_PLUGIN_DIR}/scripts/${Extensions}/GOG/gog-launcher.sh"
export ARGS_SCRIPT="${DECKY_PLUGIN_DIR}/scripts/${Extensions}/GOG/get-gog-args.sh"
export GALAXY_TOKENS="${HOME}/.var/app/com.github.sude_.lgogdownloader/config/lgogdownloader/galaxy_tokens.json"
export AUTH_TOKENS="${DECKY_PLUGIN_RUNTIME_DIR}/gog_auth.json"

DBNAME="gog.db"
# database to use for configs and metadata
DBFILE="${DECKY_PLUGIN_RUNTIME_DIR}/gog.db"

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/gogtabconfig.json" ]]; then
    TEMP="${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/gogtabconfig.json"
else
    TEMP="${DECKY_PLUGIN_DIR}/conf_schemas/gogtabconfig.json"
fi
SETTINGS=$($GOGCONF --generate-env-settings-json $TEMP --dbfile $DBFILE 2>/dev/null) || true
eval "${SETTINGS}" 2>/dev/null || true

if [[ "${GOG_INSTALLLOCATION}" == "SSD" ]]; then
    INSTALL_DIR="${HOME}/Games/gog/"
elif [[ "${GOG_INSTALLLOCATION}" == "MicroSD" ]]; then
    NVME=$(lsblk --list | grep nvme0n1\ |awk '{ print $2}' |  awk '{split($0, a,":"); print a[1]}')
    LINK=$(find /run/media -maxdepth 1  -type l )
    LINK_TARGET=$(readlink -f "${LINK}")
    MOUNT_POINT=$(lsblk --list --exclude "${NVME}" | grep part |  sed -n 's/.*part //p')
    if [[ "${MOUNT_POINT}" == "${LINK_TARGET}" ]]; then
        INSTALL_DIR="${LINK}/Games/gog/"
    else
        INSTALL_DIR="/run/media/mmcblk0p1/Games/gog/"
    fi
else
    INSTALL_DIR="${HOME}/Games/"
fi

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/gog_overrides.sh" ]]; then
   source "${DECKY_PLUGIN_RUNTIME_DIR}/gog_overrides.sh"
fi

export INSTALL_DIR
