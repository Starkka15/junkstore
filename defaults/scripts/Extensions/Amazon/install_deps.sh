#!/usr/bin/env bash
NILE_DOWNLOAD_URL="https://github.com/imLinguin/nile/releases/latest/download/nile_linux_x86_64"
NILE_BIN="${HOME}/.local/bin/nile"

function uninstall() {
    echo "Uninstalling Amazon dependencies"
    if [[ -f "${NILE_BIN}" ]]; then
        echo "Removing nile binary"
        rm -f "${NILE_BIN}"
    fi
}

function download_and_install() {
    mkdir -p "${HOME}/.local/bin"
    echo "Downloading nile from ${NILE_DOWNLOAD_URL}"
    wget -O "${NILE_BIN}" "${NILE_DOWNLOAD_URL}"
    chmod +x "${NILE_BIN}"
    echo "nile installed to ${NILE_BIN}"
}

function install() {
    if [[ -f "${NILE_BIN}" ]]; then
        echo "nile is already installed, reinstalling"
        rm -f "${NILE_BIN}"
    fi
    download_and_install
}

if [ "$1" == "uninstall" ]; then
    echo "Uninstalling dependencies: Amazon extension"
    uninstall
else
    echo "Installing dependencies: Amazon extension"
    install
fi
