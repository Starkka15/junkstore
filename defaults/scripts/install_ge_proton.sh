#!/usr/bin/env bash
# Download and install latest GE-Proton

set -e

API_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"

# Find or create compat tools directory
if [ -d "$HOME/.steam/steam/compatibilitytools.d" ]; then
    COMPAT_DIR="$HOME/.steam/steam/compatibilitytools.d"
elif [ -d "$HOME/.steam/root/compatibilitytools.d" ]; then
    COMPAT_DIR="$HOME/.steam/root/compatibilitytools.d"
else
    COMPAT_DIR="$HOME/.steam/steam/compatibilitytools.d"
    mkdir -p "$COMPAT_DIR"
fi

echo "Fetching latest GE-Proton release info..."

# Get release info
RELEASE_JSON=$(curl -sL -H "User-Agent: GameVault/1.0" "$API_URL")

TAG=$(echo "$RELEASE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null)
if [ -z "$TAG" ]; then
    echo "Error: Could not fetch release info from GitHub."
    echo "Check your internet connection."
    exit 1
fi

echo "Latest release: $TAG"

# Check if already installed
if [ -d "$COMPAT_DIR/$TAG" ]; then
    echo "$TAG is already installed at $COMPAT_DIR/$TAG"
    echo "Done!"
    exit 0
fi

# Get download URL
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for asset in data.get('assets', []):
    if asset['name'].endswith('.tar.gz'):
        print(asset['browser_download_url'])
        break
" 2>/dev/null)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No .tar.gz asset found in release."
    exit 1
fi

FILENAME="${TAG}.tar.gz"
TMP_FILE="/tmp/${FILENAME}"

echo "Downloading $TAG... This may take a few minutes (~500MB)."
echo "URL: $DOWNLOAD_URL"

# Download silently (progress bars use \r which doesn't stream over WebSocket)
curl -sL -o "$TMP_FILE" "$DOWNLOAD_URL"

echo "Download complete. Extracting to $COMPAT_DIR..."

# Extract
tar -xzf "$TMP_FILE" -C "$COMPAT_DIR"

# Clean up
rm -f "$TMP_FILE"

echo ""
echo "Successfully installed $TAG!"
echo "Restart Steam for the new compatibility tool to appear."
