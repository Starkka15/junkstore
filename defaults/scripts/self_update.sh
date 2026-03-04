#!/usr/bin/env bash
set -euo pipefail

DOWNLOAD_URL="$1"
PLUGIN_DIR="${DECKY_PLUGIN_DIR:-.}"
TIMESTAMP=$(date +%s)
TMP_ZIP="/tmp/gamevault_update.zip"
TMP_EXTRACT="/tmp/gamevault_update_extract"
BACKUP_DIR="/tmp/gamevault_backup_${TIMESTAMP}"

echo "==================================="
echo "  GameVault Self-Update"
echo "  Do not navigate away please..."
echo "==================================="

# Step 1: Download
echo ""
echo "[1/5] Downloading update..."
if ! curl -fSL -o "$TMP_ZIP" "$DOWNLOAD_URL"; then
    echo "ERROR: Download failed. No changes were made."
    exit 1
fi

# Step 2: Validate zip
echo "[2/5] Validating download..."
if ! unzip -t "$TMP_ZIP" > /dev/null 2>&1; then
    echo "ERROR: Downloaded file is not a valid zip. No changes were made."
    rm -f "$TMP_ZIP"
    exit 1
fi

# Step 3: Backup current plugin
echo "[3/5] Backing up current installation to ${BACKUP_DIR}..."
mkdir -p "$BACKUP_DIR"
sudo cp -a "$PLUGIN_DIR/." "$BACKUP_DIR/"
echo "Backup created at: ${BACKUP_DIR}"

# Step 4: Extract to temp, then copy into plugin dir
echo "[4/5] Installing update..."

# Clean up temp extract dir if it exists
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q -o "$TMP_ZIP" -d "$TMP_EXTRACT"

# GitHub zipball extracts into a subdirectory (owner-repo-hash/)
# Find it automatically
EXTRACTED_DIR=$(find "$TMP_EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo "ERROR: Could not find extracted directory. Restoring backup..."
    sudo cp -a "$BACKUP_DIR/." "$PLUGIN_DIR/"
    rm -rf "$TMP_EXTRACT" "$TMP_ZIP"
    exit 1
fi

# Remove replaceable directories from plugin dir
for dir in dist scripts py_modules conf_schemas; do
    if [ -d "$PLUGIN_DIR/$dir" ]; then
        sudo rm -rf "$PLUGIN_DIR/$dir"
        echo "  Removed old $dir/"
    fi
done

# Remove replaceable root files
for file in main.py plugin.json package.json LICENSE README.md; do
    if [ -f "$PLUGIN_DIR/$file" ]; then
        sudo rm -f "$PLUGIN_DIR/$file"
    fi
done

# Copy new files into plugin dir
sudo cp -a "$EXTRACTED_DIR/." "$PLUGIN_DIR/"

# Make scripts executable
if [ -d "$PLUGIN_DIR/scripts" ]; then
    sudo find "$PLUGIN_DIR/scripts" -type f -exec chmod 755 {} \;
fi
if [ -d "$PLUGIN_DIR/defaults/scripts" ]; then
    sudo find "$PLUGIN_DIR/defaults/scripts" -type f -exec chmod 755 {} \;
fi

echo "[5/5] Update installed successfully!"

# Cleanup temp files
rm -rf "$TMP_EXTRACT" "$TMP_ZIP"

echo ""
echo "==================================="
echo "  Update complete!"
echo "  Restarting Decky Loader..."
echo "==================================="

# Restart Decky Loader to pick up changes
sudo systemctl restart plugin_loader.service
