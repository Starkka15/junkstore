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

source "${DECKY_PLUGIN_DIR}/scripts/Extensions/Itchio/settings.sh"

API_KEY_FILE="${DECKY_PLUGIN_RUNTIME_DIR}/itchio_api_key"
API_KEYS_URL="https://itch.io/user/settings/api-keys"

# Find a browser (prefer Firefox)
BROWSER=""
if flatpak list --app --columns=application 2>/dev/null | grep -q 'org.mozilla.firefox'; then
    BROWSER="flatpak run org.mozilla.firefox"
elif command -v firefox &>/dev/null; then
    BROWSER="firefox"
elif command -v chromium &>/dev/null; then
    BROWSER="chromium"
else
    BROWSER="xdg-open"
fi

# Open the API keys page
echo "Opening itch.io API keys page..."
$BROWSER "${API_KEYS_URL}" &>/dev/null &

# Show dialog to get the API key
API_KEY=""
if command -v kdialog &>/dev/null; then
    API_KEY=$(kdialog --title "itch.io Login" --inputbox \
        "1. Click 'Generate new API key' on the page
2. Copy the generated key
3. Paste it here and click OK" 2>/dev/null)
elif command -v zenity &>/dev/null; then
    API_KEY=$(zenity --entry --title "itch.io Login" --text \
        "1. Click 'Generate new API key' on the page\n2. Copy the generated key\n3. Paste it here and click OK" \
        --width 500 2>/dev/null)
else
    echo "No dialog tool available (kdialog/zenity)" >> "${DECKY_PLUGIN_LOG_DIR}/itchiologin.log"
fi

if [[ -n "${API_KEY}" ]]; then
    # Verify the key works
    RESULT=$(curl -s "https://itch.io/api/1/${API_KEY}/me")
    if echo "${RESULT}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('username',''))" 2>/dev/null | grep -q .; then
        echo "${API_KEY}" > "${API_KEY_FILE}"
        echo "API key saved successfully" >> "${DECKY_PLUGIN_LOG_DIR}/itchiologin.log"
    else
        echo "Invalid API key" >> "${DECKY_PLUGIN_LOG_DIR}/itchiologin.log"
        if command -v kdialog &>/dev/null; then
            kdialog --error "Invalid API key. Please try again." 2>/dev/null
        elif command -v zenity &>/dev/null; then
            zenity --error --text "Invalid API key. Please try again." 2>/dev/null
        fi
    fi
else
    echo "No API key provided" >> "${DECKY_PLUGIN_LOG_DIR}/itchiologin.log"
fi

"${DECKY_PLUGIN_DIR}/scripts/junk-store.sh" Itchio loginstatus --flush-cache
