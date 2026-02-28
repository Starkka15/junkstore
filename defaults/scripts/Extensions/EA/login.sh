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

source "${DECKY_PLUGIN_DIR}/scripts/Extensions/EA/settings.sh"

# maxima-cli handles OAuth login internally
# Running account-info triggers the login flow if not logged in
# It opens a browser to EA's OAuth page and listens on port 31033 for the callback
echo "Starting EA Play login..." >> "${DECKY_PLUGIN_LOG_DIR}/ealogin.log"

$MAXIMA_CMD account-info &>> "${DECKY_PLUGIN_LOG_DIR}/ealogin.log"

if [ $? -eq 0 ]; then
    echo "Login successful" >> "${DECKY_PLUGIN_LOG_DIR}/ealogin.log"
else
    echo "Login failed" >> "${DECKY_PLUGIN_LOG_DIR}/ealogin.log"
fi

"${DECKY_PLUGIN_DIR}/scripts/junk-store.sh" EA loginstatus --flush-cache
