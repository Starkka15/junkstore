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

source "${DECKY_PLUGIN_DIR}/scripts/Extensions/Amazon/settings.sh"

python3 "${DECKY_PLUGIN_DIR}/scripts/oauth_helper.py" amazon "${NILE}" &>> "${DECKY_PLUGIN_LOG_DIR}/amazonlogin.log"
"${DECKY_PLUGIN_DIR}/scripts/junk-store.sh" Amazon loginstatus --flush-cache
