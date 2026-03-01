#!/usr/bin/env bash

# Register actions with the junk-store.sh script
ACTIONS+=("update-umu-id" "download-saves" "upload-saves" "toggle-autosync")

# Register GOG as a platform with the junk-store.sh script
PLATFORMS+=("GOG")


# only source the settings if the platform is GOG - this is to avoid conflicts with other plugins
if [[ "${PLATFORM}" == "GOG" ]]; then
    source "${DECKY_PLUGIN_DIR}/scripts/${Extensions}/GOG/settings.sh"
fi

function GOG_init() {
    $GOGCONF --list --dbfile $DBFILE &> /dev/null
}

function GOG_refresh() {
    TEMP=$(GOG_init)
    echo "{\"Type\": \"RefreshContent\", \"Content\": {\"Message\": \"Refreshed\"}}"
}
function GOG_getgames(){
    if [ -z "${1}" ]; then
        FILTER=""
    else
        FILTER="${1}"
    fi
    if [ -z "${2}" ]; then
        INSTALLED="false"
    else
        INSTALLED="${2}"
    fi
     if [ -z "${3}" ]; then
        LIMIT="true"
    else
        LIMIT="${3}"
    fi
    IMAGE_PATH=""
    TEMP=$($GOGCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile $DBFILE)
    echo $TEMP >> $DECKY_PLUGIN_LOG_DIR/debug.log
    if echo "$TEMP" | jq -e '.Content.Games | length == 0' &>/dev/null; then
        if [[ $FILTER == "" ]] && [[ $INSTALLED == "false" ]]; then
            TEMP=$(GOG_init)
            TEMP=$($GOGCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile $DBFILE)
        fi
    fi
    echo $TEMP
}
function GOG_saveplatformconfig(){
    cat | $GOGCONF --parsejson "${1}" --dbfile $DBFILE --platform Proton --fork "" --version "" --dbfile $DBFILE
}
function GOG_getplatformconfig(){
    TEMP=$($GOGCONF --confjson "${1}" --platform Proton --fork "" --version "" --dbfile $DBFILE)
    echo $TEMP
}

function GOG_cancelinstall(){
    PID=$(cat "${DECKY_PLUGIN_LOG_DIR}/${1}.pid")
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    killall -w gogdl
    rm "${DECKY_PLUGIN_LOG_DIR}/${1}.pid" 2>/dev/null
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"${1} installation Cancelled\"}}"
}

function GOG_download(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    mkdir -p "${INSTALL_DIR}"
    gogupdategamedetailsaftercmd $1 $GOGDL --auth-config-path "${AUTH_TOKENS}" download $1 --platform windows --path "${INSTALL_DIR}" --lang "${GOG_LANGUAGE:-en}" --with-dlcs 2> $PROGRESS_LOG > "${DECKY_PLUGIN_LOG_DIR}/${1}.output" &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Downloading\"}}"

}

function GOG_update(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    gogupdategamedetailsaftercmd $1 $GOGDL --auth-config-path "${AUTH_TOKENS}" update $1 --platform windows --path "${INSTALL_DIR}" --lang "${GOG_LANGUAGE:-en}" >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Updating\"}}"

}

function GOG_verify(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    $GOGDL --auth-config-path "${AUTH_TOKENS}" repair $1 --platform windows --path "${INSTALL_DIR}" >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Verifying\"}}"

}
function GOG_repair(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    gogupdategamedetailsaftercmd $1 $GOGDL --auth-config-path "${AUTH_TOKENS}" repair $1 --platform windows --path "${INSTALL_DIR}" >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Repairing\"}}"

}

function GOG_install(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    rm $PROGRESS_LOG &>> ${DECKY_PLUGIN_LOG_DIR}/${1}.log

    # Find and process goggame-{id}.info to extract exe path
    INFO_FILENAME="goggame-${1}.info"
    pushd "${INSTALL_DIR}" &>> ${DECKY_PLUGIN_LOG_DIR}/${1}.log
    GAME_INFO=$(find . -type f -name $INFO_FILENAME)
    echo "Game info: ${GAME_INFO}" >> /dev/stderr
    popd &>> ${DECKY_PLUGIN_LOG_DIR}/${1}.log

    if [[ -n "${GAME_INFO}" ]]; then
        $GOGCONF --process-info-file "${GAME_INFO}" --dbfile $DBFILE
    fi

    RESULT=$($GOGCONF --addsteamclientid "${1}" "${2}" --dbfile $DBFILE)
    TEMP=$($GOGCONF --update-umu-id "${1}" gog --dbfile $DBFILE)
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($GOGCONF --launchoptions "${1}" "${ARGS}" "" --dbfile $DBFILE)
    echo $TEMP
    exit 0
}

function GOG_getlaunchoptions(){
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($GOGCONF --launchoptions "${1}" "${ARGS}" "" --dbfile $DBFILE)
    echo $TEMP
    exit 0
}

function GOG_uninstall(){
    GAME_DIR=$($GOGCONF --get-game-dir "${1}" --dbfile $DBFILE)
    if [ -d "${GAME_DIR}" ]; then
        rm -rf "${GAME_DIR}"
    fi
    TEMP=$($GOGCONF --clearsteamclientid "${1}" --dbfile $DBFILE)
    echo $TEMP

}
function GOG_getgamedetails(){
    IMAGE_PATH=""
    TEMP=$($GOGCONF --getgamedata "${1}" "${IMAGE_PATH}" --dbfile $DBFILE --forkname "Proton" --version "null" --platform "Windows")
    echo $TEMP
    exit 0
}

function GOG_getgamesize(){
    TEMP=$($GOGCONF --get-game-size "${1}" "${2}"  --dbfile $DBFILE)
    echo $TEMP
}

function GOG_getprogress()
{
    TEMP=$($GOGCONF --getprogress "${DECKY_PLUGIN_LOG_DIR}/${1}.progress" --dbfile $DBFILE)
    echo $TEMP
}
function GOG_loginstatus(){
    if [[ -z $1 ]]; then
        FLUSH_CACHE=""
    else
        FLUSH_CACHE="--flush-cache"
    fi
    TEMP=$($GOGCONF --getloginstatus --dbfile $DBFILE $FLUSH_CACHE)
    echo $TEMP

}

function GOG_login(){
    get_steam_env
    launchoptions "${DECKY_PLUGIN_DIR}/scripts/Extensions/GOG/login.sh" "" "${DECKY_PLUGIN_LOG_DIR}" "GOG Login"
}
function GOG_login-launch-options(){
    get_steam_env
    loginlaunchoptions  "${DECKY_PLUGIN_DIR}/scripts/Extensions/GOG/login.sh" "" "${DECKY_PLUGIN_LOG_DIR}" "GOG Login"
}


function GOG_logout(){
    rm -f "${HOME}/.var/app/com.github.sude_.lgogdownloader/config/lgogdownloader/cookies.txt" 2>/dev/null
    rm -f "${GALAXY_TOKENS}" 2>/dev/null
    rm -f "${AUTH_TOKENS}" 2>/dev/null
    GOG_loginstatus --flush-cache
}

function GOG_toggle-autosync(){
    TEMP=$($GOGCONF --toggle-autosync "${1}" --dbfile $DBFILE)
    echo "$TEMP"
}
function GOG_update-umu-id(){
    TEMP=$($GOGCONF --update-umu-id "${1}" gog --dbfile $DBFILE)
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"Umu Id updated\"}}"
}

function GOG_download-saves(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    STEAM_CLIENT_ID="${2}"
    if [[ -z "${STEAM_CLIENT_ID}" ]]; then
        echo '{"Type": "Error", "Content": {"Message": "No SteamClientID - launch game once first"}}'
        return
    fi
    pushd "${DECKY_PLUGIN_DIR}" > /dev/null
    $GOGCONF --sync-saves "${1}" --skip-upload --dbfile $DBFILE >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    popd > /dev/null
    echo '{"Type": "Progress", "Content": {"Message": "Downloading Saves"}}'
}

function GOG_upload-saves(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    STEAM_CLIENT_ID="${2}"
    if [[ -z "${STEAM_CLIENT_ID}" ]]; then
        echo '{"Type": "Error", "Content": {"Message": "No SteamClientID - launch game once first"}}'
        return
    fi
    pushd "${DECKY_PLUGIN_DIR}" > /dev/null
    $GOGCONF --sync-saves "${1}" --skip-download --dbfile $DBFILE >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    popd > /dev/null
    echo '{"Type": "Progress", "Content": {"Message": "Uploading Saves"}}'
}

function GOG_run-exe(){
    get_steam_env
    SETTINGS=$($GOGCONF --get-env-settings $ID --dbfile $DBFILE)
    eval "${SETTINGS}"
    STEAM_ID="${1}"
    GAME_SHORTNAME="${2}"
    GAME_EXE="${3}"
    ARGS="${4}"
    if [[ $4 == true ]]; then
        ARGS="some value"
    else
        ARGS=""
    fi
    COMPAT_TOOL="${5}"
    GAME_PATH=$($GOGCONF --get-game-dir $GAME_SHORTNAME --dbfile $DBFILE)
    launchoptions "\\\"${GAME_PATH}/${GAME_EXE}\\\""  "${ARGS}  &> ${DECKY_PLUGIN_LOG_DIR}/run-exe.log" "${GAME_PATH}" "Run exe" true "${COMPAT_TOOL}"
}
function GOG_get-exe-list(){
    get_steam_env
    STEAM_ID="${1}"
    GAME_SHORTNAME="${2}"
    GAME_PATH=$($GOGCONF --get-game-dir $GAME_SHORTNAME --dbfile $DBFILE)
    export STEAM_COMPAT_DATA_PATH="${HOME}/.local/share/Steam/steamapps/compatdata/${STEAM_ID}"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="${GAME_PATH}"
    cd "${STEAM_COMPAT_CLIENT_INSTALL_PATH}"
    JSON="{\"Type\": \"FileContent\", \"Content\": {\"PathRoot\": \"${GAME_PATH}\", \"Files\": ["
    SEP=""

    while IFS= read -r -d '' FILE; do
        JSON="${JSON}${SEP}{\"Path\": \"${FILE}\"}"
        SEP=","
    done < <(find . \( -name "*.exe" -o -iname "*.bat" -o -iname "*.msi" \) -print0)

    JSON="${JSON}]}}"
    echo "$JSON"
}

function GOG_getsetting(){
    TEMP=$($GOGCONF --getsetting $1 --dbfile $DBFILE)
    echo $TEMP
}
function GOG_savesetting(){
    $GOGCONF --savesetting $1 $2 --dbfile $DBFILE
}
function GOG_getjsonimages(){

    TEMP=$($GOGCONF --get-base64-images "${1}" --dbfile $DBFILE --offline)
    echo $TEMP
}
function GOG_gettabconfig(){
    if [[ ! -d "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas" ]]; then
        mkdir -p "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas"
    fi
    if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/gogtabconfig.json" ]]; then
        TEMP=$(cat "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/gogtabconfig.json")
    else
        TEMP=$(cat "${DECKY_PLUGIN_DIR}/conf_schemas/gogtabconfig.json")
    fi
    echo "{\"Type\":\"IniContent\", \"Content\": ${TEMP}}"
}
function GOG_savetabconfig(){

    cat > "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/gogtabconfig.json"
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"GOG tab config saved\"}}"

}

function gogupdategamedetailsaftercmd() {
    game=$1
    shift
    "$@"
    $GOGCONF --update-game-details $game --dbfile $DBFILE &> /dev/null
}
