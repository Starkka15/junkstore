#!/usr/bin/env bash
# These need to be exported because it does not get executed in the context of the plugin.
export DECKY_PLUGIN_RUNTIME_DIR="${HOME}/homebrew/data/Junk-Store"
export DECKY_PLUGIN_DIR="${HOME}/homebrew/plugins/Junk-Store"
export DECKY_PLUGIN_LOG_DIR="${HOME}/homebrew/logs/Junk-Store"
export WORKING_DIR=$DECKY_PLUGIN_DIR
export Extensions="Extensions"
ID=$1
echo $1
shift



#########################################################################
# If you enable cloud saves and things go wrong, you got what you       #
# deserved this is a minefield and a lot can go wrong here.             #
# Do not ask me for support and do not cry about losing you saves,      #
# you have been warned. If you complain on a public forum I will        #
# link to this code and make sure people understand it was YOUR fault.  #
#########################################################################

function download-saves(){
    pushd "${DECKY_PLUGIN_DIR}" > /dev/null
    SAVE_PATH=$($EPICCONF --get-save-path "$ID" --dbfile $DBFILE 2>/dev/null)
    popd > /dev/null
    [[ -z "${SAVE_PATH}" ]] && return
    $LEGENDARY sync-saves "$ID" --skip-upload --save-path "${SAVE_PATH}" -y >> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log" 2>&1 || true
}

function upload-saves(){
    pushd "${DECKY_PLUGIN_DIR}" > /dev/null
    SAVE_PATH=$($EPICCONF --get-save-path "$ID" --dbfile $DBFILE 2>/dev/null)
    popd > /dev/null
    [[ -z "${SAVE_PATH}" ]] && return
    $LEGENDARY sync-saves "$ID" --skip-download --save-path "${SAVE_PATH}" -y >> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log" 2>&1 || true
}



source "${DECKY_PLUGIN_DIR}/scripts/Extensions/Epic/settings.sh"

echo "dbfile: ${DBFILE}"
SETTINGS=$($EPICCONF --get-env-settings $ID --dbfile $DBFILE --platform Proton --fork "" --version "" --dbfile $DBFILE)
echo "${SETTINGS}"
eval "${SETTINGS}"


if [[ "${RUNTIMES_ESYNC}" == "true" ]]; then
    export PROTON_NO_ESYNC=1
else
    export PROTON_NO_ESYNC=0
fi
if [[ "${RUNTIMES_FSYNC}" == "true" ]]; then
    export PROTON_NO_FSYNC=1
else
    export PROTON_NO_FSYNC=0
fi
if [[ "${RUNTIMES_VKD3D}" == "true" ]]; then
    export PROTON_USE_WINED3D=1
else
    export PROTON_USE_WINED3D=0
fi
if [[ "${RUNTIMES_VKD3D_PROTON}" == "true" ]]; then
    export PROTON_USE_WINED3D=0
    export PROTON_USE_WINED3D11=1
else
    export PROTON_USE_WINED3D11=0
fi
if [[ "${RUNTIMES_FSR}" == "true" ]]; then
    export WINE_FULLSCREEN_FSR=1
else
    export WINE_FULLSCREEN_FSR=0
fi
if [ -z "${RUNTIMES_FSR_STRENGTH}" ]; then
    unset WINE_FULLSCREEN_FSR_STRENGTH
else
    export WINE_FULLSCREEN_FSR_STRENGTH=${RUNTIMES_FSR_STRENGTH}
fi

if [[ "${RUNTIMES_LIMIT_FRAMERATE}" == "true" ]]; then
    export DXVK_FRAME_RATE=${RUNTIMES_FRAME_RATE}
fi
if [[ "${RUNTIMES_EASYANTICHEAT}" == "true" ]]; then
    echo "enabling easy anti cheat"
    export PROTON_EAC_RUNTIME="${HOME}/.steam/root/steamapps/common/Proton EasyAntiCheat Runtime/"
fi
if [[ "${RUNTIMES_BATTLEYE}" == "true"  ]]; then
    export PROTON_BATTLEYE_RUNTIME="${HOME}/.steam/root/steamapps/common/Proton BattlEye Runtime/"
fi

if [ -z "${RUNTIMES_PULSE_LATENCY_MSEC}" ]; then
    export PULSE_LATENCY_MSEC=$RUNTIMES_PULSE_LATENCY_MSEC

fi
if [[ "${RUNTIMES_RADV_PERFTEST}" == "" ]]; then
    unset RADV_PERFTEST
else
    export RADV_PERFTEST=$RUNTIMES_RADV_PERFTEST
fi
if [[ "${RUNTIMES_PROTON_FORCE_LARGE_ADDRESS_AWARE}" == "true" ]]; then
    export PROTON_FORCE_LARGE_ADDRESS_AWARE=1
else
    unset PROTON_FORCE_LARGE_ADDRESS_AWARE
fi

if [[ "${ADVANCED_VK_ICD_FILENAMES}" == "true" ]]; then
    export VK_ICD_FILENAMES="${HOME}/mesa/share/vulkan/icd.d/radeon_icd.x86_64.json"
fi
if [[ "${RUNTIMES_MESA_EXTENSION_MAX_YEAR}" == "" ]]; then
    unset MESA_EXTENSION_MAX_YEAR
else
    export MESA_EXTENSION_MAX_YEAR=$RUNTIMES_MESA_EXTENSION_MAX_YEAR
fi


CMD=${*}

echo "CMD: ${CMD}"


pushd "${DECKY_PLUGIN_DIR}" > /dev/null
AUTOSYNC=$($EPICCONF --get-autosync "$ID" --dbfile $DBFILE 2>/dev/null)
popd > /dev/null

if [[ "${AUTOSYNC}" == "1" ]]; then
    download-saves
fi


QUOTED_ARGS=""
ALL_BUT_LAST_ARG=""
REG_FIX=""
for arg in "$@"; do
    QUOTED_ARGS+=" \"${arg}\"" 
    if [[ "${arg}" != "${!#}" ]]; then
        ALL_BUT_LAST_ARG+=" \"${arg}\""
        REG_FIX+=" \"${arg}\""
    else
        ALL_BUT_LAST_ARG+=" \"install_deps.bat\""
    fi
done

ARGS=""
if [[ -f "${ARGS_SCRIPT}" ]]; then
    ARGS=$("${ARGS_SCRIPT}" "$ID")
fi
if [[ "${ADVANCED_IGNORE_EPIC_ARGS}" == "true" ]]; then
    ARGS="${ADVANCED_ARGUMENTS}"
else
    ARGS="${ARGS} ${ADVANCED_ARGUMENTS}"
fi


echo "ARGS: ${ARGS}" &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
for arg in $ARGS; do
    QUOTED_ARGS+=" ${arg}" 
    
done

pushd "${DECKY_PLUGIN_DIR}"
GAME_PATH=$($EPICCONF --get-game-dir "$ID" --dbfile $DBFILE --offline)
popd
echo "game path: ${GAME_PATH}" &> "${GAME_PATH}/launcher.log"
export STEAM_COMPAT_INSTALL_PATH=${GAME_PATH}
if [[ "${ADVANCED_SET_STEAM_COMPAT_LIBRARY_PATHS}" == "true" ]]; then
    export STEAM_COMPAT_LIBRARY_PATHS=${STEAM_COMPAT_LIBRARY_PATHS}:${GAME_PATH}
fi
export PROTON_SET_GAME_DRIVE="gamedrive"
if [ -f "${GAME_PATH}/install.done" ]; then
    echo "install_deps.bat exists"
    echo "install_deps.bat exists" &>> "${GAME_PATH}/launcher.log"
    pwd &>> "${GAME_PATH}/launcher.log"
else
    echo "installing deps" &>> "${GAME_PATH}/launcher.log"
    echo "install_deps.bat does not exist"
    pwd &>> "${GAME_PATH}/launcher.log"
    #echo "$(echo -e "${REG_FIX} reg add HKEY_CLASSES_ROOT\\\\\\\\\\\\\\\\com.epicgames.launcher /f")" &>> "${GAME_PATH}/launcher.log"
  
    echo "reg add HKEY_CLASSES_ROOT\\com.epicgames.launcher /f" > "${GAME_PATH}/install_deps.bat"
    #eval "$(echo -e "${REG_FIX} reg add HKEY_CLASSES_ROOT\\\\\\\\\\\\\\\\com.epicgames.launcher /f")" &>> "${GAME_PATH}/launcher.log"
   
    echo "EpicOnlineServices\\EpicOnlineServicesInstaller.exe" >> "${GAME_PATH}/install_deps.bat"
    echo "echo \"install done\" > install.done" >> "${GAME_PATH}/install_deps.bat"
   

    echo "running install_deps.bat" >> "${GAME_PATH}/launcher.log"
    pushd "${GAME_PATH}"
  
    echo "path: ${GAME_PATH}" &>> "${GAME_PATH}/launcher.log"
    echo "$(echo -e "$ALL_BUT_LAST_ARG")" &>> "${GAME_PATH}/launcher.log"
    eval "$(echo -e "$ALL_BUT_LAST_ARG")"  # &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
    popd
fi

echo -e "Running: ${QUOTED_ARGS}" >> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"

UMU_ID=""

if [[ "${EPIC_ENABLE_UMU_FIXES}" != "false" ]]; then
    export STORE="egs"
    UMU_ID=$($EPICCONF --get-umu-id "$ID" --dbfile $DBFILE)
    export UMU_ID="${UMU_ID}"
fi

if [[ "${UMU_ID}" == "" ]]; then
    unset UMU_ID
    unset STORE
fi

if [ -f "$HOME/.local/lib/liblsfg-vk.so" ]; then
    if [[ "${DISABLE_LSFGVK}" != "1" && "${DISABLE_LSFGVK}" != "true" ]]; then
        export LD_PRELOAD="$HOME/.local/lib/:${LD_PRELOAD}"
        echo "LSFG-VK enabled" &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
    else
        echo "LSFG-VK disabled for this game" &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
    fi
else
    echo "LSFG-VK not installed" &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
fi

eval "$(echo -e "${ADVANCED_VARIABLES}")" &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
eval "$(echo -e "$QUOTED_ARGS")"  &>> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"
# eval "${CMD:q} ${ARGS}"  &> "${DECKY_PLUGIN_LOG_DIR}/${ID}.log"

if [[ "${AUTOSYNC}" == "1" ]]; then
    upload-saves
fi


# echo "#!/usr/bin/env bash" > run.sh
# echo "${CMD} ${ARGS}" >> run.sh
# chmod +x run.sh
# ./run.sh && rm run.sh
 
