#!/usr/bin/env bash
# These need to be exported because it does not get executed in the context of the plugin.
export DECKY_PLUGIN_RUNTIME_DIR="${HOME}/homebrew/data/GameVault"
export DECKY_PLUGIN_DIR="${HOME}/homebrew/plugins/GameVault"
export DECKY_PLUGIN_LOG_DIR="${HOME}/homebrew/logs/GameVault"
export WORKING_DIR=$DECKY_PLUGIN_DIR
export Extensions="Extensions"
ID=$1
echo $1
shift

source "${DECKY_PLUGIN_DIR}/scripts/Extensions/GOG/settings.sh"

cd $DECKY_PLUGIN_DIR
python3 "${DECKY_PLUGIN_DIR}/scripts/oauth_helper.py" gog "${AUTH_TOKENS}" 2>&1 | tee "${DECKY_PLUGIN_LOG_DIR}/gog-login.log"
if [[ -f "${AUTH_TOKENS}" ]]; then
    echo "Auth tokens saved successfully" >> "${DECKY_PLUGIN_LOG_DIR}/gog-login.log"
    $GOGDL --auth-config-path "${AUTH_TOKENS}" auth &> "${DECKY_PLUGIN_LOG_DIR}/gog-auth.log"
else
    echo "ERROR: Auth tokens file was not created" >> "${DECKY_PLUGIN_LOG_DIR}/gog-login.log"
fi
"${DECKY_PLUGIN_DIR}/scripts/gamevault.sh" GOG loginstatus --flush-cache
