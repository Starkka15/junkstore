#!/usr/bin/env bash

# Register actions with the junk-store.sh script
ACTIONS+=("update-umu-id")

# Register Amazon as a platform with the junk-store.sh script
PLATFORMS+=("Amazon")


# only source the settings if the platform is Amazon - this is to avoid conflicts with other plugins
if [[ "${PLATFORM}" == "Amazon" ]]; then
    source "${DECKY_PLUGIN_DIR}/scripts/${Extensions}/Amazon/settings.sh"
fi

function Amazon_init() {
    $AMAZONCONF --list --dbfile $DBFILE &> /dev/null
}

function Amazon_refresh() {
    TEMP=$(Amazon_init)
    echo "{\"Type\": \"RefreshContent\", \"Content\": {\"Message\": \"Refreshed\"}}"
}
function Amazon_getgames(){
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
    TEMP=$($AMAZONCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile $DBFILE)
    echo $TEMP >> $DECKY_PLUGIN_LOG_DIR/debug.log
    if echo "$TEMP" | jq -e '.Content.Games | length == 0' &>/dev/null; then
        if [[ $FILTER == "" ]] && [[ $INSTALLED == "false" ]]; then
            TEMP=$(Amazon_init)
            TEMP=$($AMAZONCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile $DBFILE)
        fi
    fi
    echo $TEMP
}
function Amazon_saveplatformconfig(){
    cat | $AMAZONCONF --parsejson "${1}" --dbfile $DBFILE --platform Proton --fork "" --version "" --dbfile $DBFILE
}
function Amazon_getplatformconfig(){
    TEMP=$($AMAZONCONF --confjson "${1}" --platform Proton --fork "" --version "" --dbfile $DBFILE)
    echo $TEMP
}

function Amazon_cancelinstall(){
    PID=$(cat "${DECKY_PLUGIN_LOG_DIR}/${1}.pid")
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    killall -w nile
    rm "${DECKY_PLUGIN_LOG_DIR}/${1}.pid" 2>/dev/null
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"${1} installation Cancelled\"}}"
}

function Amazon_download(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    mkdir -p "${INSTALL_DIR}"
    amazonupdategamedetailsaftercmd $1 $NILE install --base-path "${INSTALL_DIR}" $1 2> $PROGRESS_LOG > "${DECKY_PLUGIN_LOG_DIR}/${1}.output" &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Downloading\"}}"

}

function Amazon_update(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    amazonupdategamedetailsaftercmd $1 $NILE update $1 >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Updating\"}}"

}

function Amazon_verify(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    GAME_DIR=$($AMAZONCONF --get-game-dir "${1}" --dbfile $DBFILE)
    $NILE verify --path "${GAME_DIR}" $1 >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Verifying\"}}"

}
function Amazon_repair(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    GAME_DIR=$($AMAZONCONF --get-game-dir "${1}" --dbfile $DBFILE)
    amazonupdategamedetailsaftercmd $1 $NILE verify --path "${GAME_DIR}" $1 >> "${DECKY_PLUGIN_LOG_DIR}/${1}.log" 2>> $PROGRESS_LOG &
    echo $! > "${DECKY_PLUGIN_LOG_DIR}/${1}.pid"
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Repairing\"}}"

}

function Amazon_install(){
    PROGRESS_LOG="${DECKY_PLUGIN_LOG_DIR}/${1}.progress"
    rm $PROGRESS_LOG &>> ${DECKY_PLUGIN_LOG_DIR}/${1}.log

    # Process fuel.json to extract actual game exe path
    $AMAZONCONF --process-fuel-json "${1}" --dbfile $DBFILE

    RESULT=$($AMAZONCONF --addsteamclientid "${1}" "${2}" --dbfile $DBFILE)
    TEMP=$($AMAZONCONF --update-umu-id "${1}" amazon --dbfile $DBFILE)
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($AMAZONCONF --launchoptions "${1}" "${ARGS}" "" --dbfile $DBFILE)
    echo $TEMP
    exit 0
}

function Amazon_getlaunchoptions(){
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($AMAZONCONF --launchoptions "${1}" "${ARGS}" "" --dbfile $DBFILE)
    echo $TEMP
    exit 0
}

function Amazon_uninstall(){
    $NILE uninstall $1 &>> "${DECKY_PLUGIN_LOG_DIR}/${1}.log"
    TEMP=$($AMAZONCONF --clearsteamclientid "${1}" --dbfile $DBFILE)
    echo $TEMP

}
function Amazon_getgamedetails(){
    IMAGE_PATH=""
    TEMP=$($AMAZONCONF --getgamedata "${1}" "${IMAGE_PATH}" --dbfile $DBFILE --forkname "Proton" --version "null" --platform "Windows")
    echo $TEMP
    exit 0
}

function Amazon_getgamesize(){
    TEMP=$($AMAZONCONF --get-game-size "${1}" "${2}"  --dbfile $DBFILE)
    echo $TEMP
}

function Amazon_getprogress()
{
    TEMP=$($AMAZONCONF --getprogress "${DECKY_PLUGIN_LOG_DIR}/${1}.progress" --dbfile $DBFILE)
    echo $TEMP
}
function Amazon_loginstatus(){
    if [[ -z $1 ]]; then
        FLUSH_CACHE=""
    else
        FLUSH_CACHE="--flush-cache"
    fi
    TEMP=$($AMAZONCONF --getloginstatus --dbfile $DBFILE $FLUSH_CACHE)
    echo $TEMP

}

function Amazon_login(){
    get_steam_env
    launchoptions "${DECKY_PLUGIN_DIR}/scripts/Extensions/Amazon/login.sh" "" "${DECKY_PLUGIN_LOG_DIR}" "Amazon Games Login"
}
function Amazon_login-launch-options(){
    get_steam_env
    loginlaunchoptions  "${DECKY_PLUGIN_DIR}/scripts/Extensions/Amazon/login.sh" "" "${DECKY_PLUGIN_LOG_DIR}" "Amazon Games Login"
}


function Amazon_logout(){
    $NILE auth --logout &>> "${DECKY_PLUGIN_LOG_DIR}/amazonlogout.log" || true
    rm -f "${HOME}/.config/nile/user.json" 2>/dev/null
    Amazon_loginstatus --flush-cache
}

function Amazon_update-umu-id(){
    TEMP=$($AMAZONCONF --update-umu-id "${1}" amazon --dbfile $DBFILE)
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"Umu Id updated\"}}"
}

function Amazon_run-exe(){
    get_steam_env
    SETTINGS=$($AMAZONCONF --get-env-settings $ID --dbfile $DBFILE)
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
    GAME_PATH=$($AMAZONCONF --get-game-dir $GAME_SHORTNAME --dbfile $DBFILE)
    launchoptions "\\\"${GAME_PATH}/${GAME_EXE}\\\""  "${ARGS}  &> ${DECKY_PLUGIN_LOG_DIR}/run-exe.log" "${GAME_PATH}" "Run exe" true "${COMPAT_TOOL}"
}
function Amazon_get-exe-list(){
    get_steam_env
    STEAM_ID="${1}"
    GAME_SHORTNAME="${2}"
    GAME_PATH=$($AMAZONCONF --get-game-dir $GAME_SHORTNAME --dbfile $DBFILE)
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

function Amazon_getsetting(){
    TEMP=$($AMAZONCONF --getsetting $1 --dbfile $DBFILE)
    echo $TEMP
}
function Amazon_savesetting(){
    $AMAZONCONF --savesetting $1 $2 --dbfile $DBFILE
}
function Amazon_getjsonimages(){

    TEMP=$($AMAZONCONF --get-base64-images "${1}" --dbfile $DBFILE --offline)
    echo $TEMP
}
function Amazon_gettabconfig(){
    if [[ ! -d "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas" ]]; then
        mkdir -p "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas"
    fi
    if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/amazontabconfig.json" ]]; then
        TEMP=$(cat "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/amazontabconfig.json")
    else
        TEMP=$(cat "${DECKY_PLUGIN_DIR}/conf_schemas/amazontabconfig.json")
    fi
    echo "{\"Type\":\"IniContent\", \"Content\": ${TEMP}}"
}
function Amazon_savetabconfig(){

    cat > "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/amazontabconfig.json"
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"Amazon tab config saved\"}}"

}

function amazonupdategamedetailsaftercmd() {
    game=$1
    shift
    "$@"
    $AMAZONCONF --update-game-details $game --dbfile $DBFILE &> /dev/null
}
