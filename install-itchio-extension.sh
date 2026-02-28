#!/bin/bash
# Standalone installer for the itch.io extension for Junk Store
# This script copies the itch.io extension files to the Junk Store plugin directory.

PLUGIN_DIR="${HOME}/homebrew/plugins/Junk-Store"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "${PLUGIN_DIR}" ]]; then
    echo "Error: Junk Store plugin not found at ${PLUGIN_DIR}"
    echo "Please install Junk Store first."
    exit 1
fi

echo "Installing itch.io extension for Junk Store..."

# Create directories
mkdir -p "${PLUGIN_DIR}/scripts/Extensions/Itchio"
mkdir -p "${PLUGIN_DIR}/conf_schemas"

# Copy extension shell scripts
echo "Copying extension scripts..."
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/store.sh" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/settings.sh" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/static.json" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/itchio-launcher.sh" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/get-itchio-args.sh" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/login.sh" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"
cp "${SCRIPT_DIR}/defaults/scripts/Extensions/Itchio/install_deps.sh" "${PLUGIN_DIR}/scripts/Extensions/Itchio/"

# Copy Python scripts
echo "Copying Python scripts..."
cp "${SCRIPT_DIR}/defaults/scripts/itchio.py" "${PLUGIN_DIR}/scripts/"
cp "${SCRIPT_DIR}/defaults/scripts/itchio-config.py" "${PLUGIN_DIR}/scripts/"

# Copy config schema
echo "Copying config schema..."
cp "${SCRIPT_DIR}/defaults/conf_schemas/itchiotabconfig.json" "${PLUGIN_DIR}/conf_schemas/"

# Make scripts executable
echo "Setting permissions..."
chmod +x "${PLUGIN_DIR}/scripts/Extensions/Itchio/store.sh"
chmod +x "${PLUGIN_DIR}/scripts/Extensions/Itchio/settings.sh"
chmod +x "${PLUGIN_DIR}/scripts/Extensions/Itchio/itchio-launcher.sh"
chmod +x "${PLUGIN_DIR}/scripts/Extensions/Itchio/get-itchio-args.sh"
chmod +x "${PLUGIN_DIR}/scripts/Extensions/Itchio/login.sh"
chmod +x "${PLUGIN_DIR}/scripts/Extensions/Itchio/install_deps.sh"
chmod +x "${PLUGIN_DIR}/scripts/itchio.py"
chmod +x "${PLUGIN_DIR}/scripts/itchio-config.py"

echo ""
echo "itch.io extension installed successfully!"
echo "Restart Decky Loader to activate the itch.io extension."
echo ""
echo "Optional: Install archive extraction dependencies (unrar, 7z) by running:"
echo "  ${PLUGIN_DIR}/scripts/Extensions/Itchio/install_deps.sh"
