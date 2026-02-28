#!/usr/bin/env bash

# Register actions with the junk-store.sh script
ACTIONS+=("update-umu-id")

# Register Itchio as a platform with the junk-store.sh script
PLATFORMS+=("Itchio")


# only source the settings if the platform is Itchio - this is to avoid conflicts with other plugins
if [[ "${PLATFORM}" == "Itchio" ]]; then
    source "${DECKY_PLUGIN_DIR}/scripts/${Extensions}/Itchio/settings.sh"
fi

function Itchio_init() {
    $ITCHIOCONF --list --dbfile $DBFILE &> /dev/null
}

function Itchio_refresh() {
    TEMP=$(Itchio_init)
    echo "{\"Type\": \"RefreshContent\", \"Content\": {\"Message\": \"Refreshed\"}}"
}
function Itchio_getgames(){
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
    TEMP=$($ITCHIOCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile $DBFILE)
    echo $TEMP >> $DECKY_PLUGIN_LOG_DIR/debug.log
    if echo "$TEMP" | jq -e '.Content.Games | length == 0' &>/dev/null; then
        if [[ $FILTER == "" ]] && [[ $INSTALLED == "false" ]]; then
            TEMP=$(Itchio_init)
            TEMP=$($ITCHIOCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile $DBFILE)
        fi
    fi
    echo $TEMP
}
function Itchio_saveplatformconfig(){
    cat | $ITCHIOCONF --parsejson "${1}" --dbfile $DBFILE --platform Proton --fork "" --version "" --dbfile $DBFILE
}
function Itchio_getplatformconfig(){
    TEMP=$($ITCHIOCONF --confjson "${1}" --platform Proton --fork "" --version "" --dbfile $DBFILE)
    echo $TEMP
}

function Itchio_cancelinstall(){
    PID=$(cat "${DECKY_PLUGIN_LOG_DIR}/${1}.pid" 2>/dev/null)
    if [[ -n "${PID}" ]]; then
        kill $PID 2>/dev/null
        wait $PID 2>/dev/null
    fi
    rm "${DECKY_PLUGIN_LOG_DIR}/${1}.pid" 2>/dev/null
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"${1} installation Cancelled\"}}"
}

function Itchio_download(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    mkdir -p "${INSTALL_DIR}"
    $ITCHIOCONF --download-game "${1}" --install-dir "${INSTALL_DIR}" --dbfile $DBFILE 2> $PROGRESS_LOG > "${DECKY_PLUGIN_LOG_DIR}/${1}.output" &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Downloading\"}}"

}

function Itchio_install(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    rm $PROGRESS_LOG &>> ${DECKY_PLUGIN_LOG_DIR}/${1}.log

    # Detect executable in installed game directory
    $ITCHIOCONF --detect-executable "${1}" --dbfile $DBFILE

    RESULT=$($ITCHIOCONF --addsteamclientid "${1}" "${2}" --dbfile $DBFILE)
    TEMP=$($ITCHIOCONF --update-umu-id "${1}" itchio --dbfile $DBFILE)
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($ITCHIOCONF --launchoptions "${1}" "${ARGS}" "" --dbfile $DBFILE)
    echo $TEMP
    exit 0
}

function Itchio_getlaunchoptions(){
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($ITCHIOCONF --launchoptions "${1}" "${ARGS}" "" --dbfile $DBFILE)
    echo $TEMP
    exit 0
}

function Itchio_uninstall(){
    GAME_DIR=$($ITCHIOCONF --get-game-dir "${1}" --dbfile $DBFILE)
    if [ -d "${GAME_DIR}" ]; then
        rm -rf "${GAME_DIR}"
    fi
    TEMP=$($ITCHIOCONF --clearsteamclientid "${1}" --dbfile $DBFILE)
    echo $TEMP

}
function Itchio_getgamedetails(){
    IMAGE_PATH=""
    TEMP=$($ITCHIOCONF --getgamedata "${1}" "${IMAGE_PATH}" --dbfile $DBFILE --forkname "Proton" --version "null" --platform "Windows")
    echo $TEMP
    exit 0
}

function Itchio_getgamesize(){
    TEMP=$($ITCHIOCONF --get-game-size "${1}" "${2}"  --dbfile $DBFILE)
    echo $TEMP
}

function Itchio_getprogress()
{
    TEMP=$($ITCHIOCONF --getprogress "${DECKY_PLUGIN_LOG_DIR}/${1}.progress" --dbfile $DBFILE)
    echo $TEMP
}
function Itchio_loginstatus(){
    if [[ -z $1 ]]; then
        FLUSH_CACHE=""
    else
        FLUSH_CACHE="--flush-cache"
    fi
    TEMP=$($ITCHIOCONF --getloginstatus --dbfile $DBFILE $FLUSH_CACHE)
    echo $TEMP

}

function Itchio_login(){
    get_steam_env
    launchoptions "${DECKY_PLUGIN_DIR}/scripts/Extensions/Itchio/login.sh" "" "${DECKY_PLUGIN_LOG_DIR}" "itch.io Login"
}
function Itchio_login-launch-options(){
    get_steam_env
    loginlaunchoptions  "${DECKY_PLUGIN_DIR}/scripts/Extensions/Itchio/login.sh" "" "${DECKY_PLUGIN_LOG_DIR}" "itch.io Login"
}


function Itchio_logout(){
    rm -f "${DECKY_PLUGIN_RUNTIME_DIR}/itchio_api_key" 2>/dev/null
    Itchio_loginstatus --flush-cache
}

function Itchio_update-umu-id(){
    TEMP=$($ITCHIOCONF --update-umu-id "${1}" itchio --dbfile $DBFILE)
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"Umu Id updated\"}}"
}

function Itchio_run-exe(){
    get_steam_env
    SETTINGS=$($ITCHIOCONF --get-env-settings $ID --dbfile $DBFILE)
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
    GAME_PATH=$($ITCHIOCONF --get-game-dir $GAME_SHORTNAME --dbfile $DBFILE)
    launchoptions "\\\"${GAME_PATH}/${GAME_EXE}\\\""  "${ARGS}  &> ${DECKY_PLUGIN_LOG_DIR}/run-exe.log" "${GAME_PATH}" "Run exe" true "${COMPAT_TOOL}"
}
function Itchio_get-exe-list(){
    get_steam_env
    STEAM_ID="${1}"
    GAME_SHORTNAME="${2}"
    GAME_PATH=$($ITCHIOCONF --get-game-dir $GAME_SHORTNAME --dbfile $DBFILE)
    export STEAM_COMPAT_DATA_PATH="${HOME}/.local/share/Steam/steamapps/compatdata/${STEAM_ID}"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="${GAME_PATH}"
    cd "${STEAM_COMPAT_CLIENT_INSTALL_PATH}"
    JSON="{\"Type\": \"FileContent\", \"Content\": {\"PathRoot\": \"${GAME_PATH}\", \"Files\": ["
    SEP=""

    while IFS= read -r -d '' FILE; do
        JSON="${JSON}${SEP}{\"Path\": \"${FILE}\"}"
        SEP=","
    done < <(find . \( -name "*.exe" -o -iname "*.bat" -o -iname "*.msi" -o -iname "*.sh" \) -print0)

    JSON="${JSON}]}}"
    echo "$JSON"
}

function Itchio_getsetting(){
    TEMP=$($ITCHIOCONF --getsetting $1 --dbfile $DBFILE)
    echo $TEMP
}
function Itchio_savesetting(){
    $ITCHIOCONF --savesetting $1 $2 --dbfile $DBFILE
}
function Itchio_getjsonimages(){

    TEMP=$($ITCHIOCONF --get-base64-images "${1}" --dbfile $DBFILE --offline)
    echo $TEMP
}
function Itchio_gettabconfig(){
    if [[ ! -d "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas" ]]; then
        mkdir -p "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas"
    fi
    if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/itchiotabconfig.json" ]]; then
        TEMP=$(cat "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/itchiotabconfig.json")
    else
        TEMP=$(cat "${DECKY_PLUGIN_DIR}/conf_schemas/itchiotabconfig.json")
    fi
    echo "{\"Type\":\"IniContent\", \"Content\": ${TEMP}}"
}
function Itchio_savetabconfig(){

    cat > "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/itchiotabconfig.json"
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"itch.io tab config saved\"}}"

}
