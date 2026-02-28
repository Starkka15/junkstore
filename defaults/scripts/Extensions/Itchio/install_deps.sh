#!/usr/bin/env bash

function uninstall() {
    echo "Uninstalling itch.io dependencies"
    echo "No external dependencies to remove"
}

function install() {
    echo "Installing itch.io dependencies (archive extraction tools)"

    # Check what's already available
    HAS_UNRAR=false
    HAS_7Z=false

    command -v unrar &>/dev/null && HAS_UNRAR=true
    (command -v 7z &>/dev/null || command -v 7za &>/dev/null) && HAS_7Z=true

    if $HAS_UNRAR && $HAS_7Z; then
        echo "All archive tools already installed"
        return
    fi

    # Try pacman (SteamOS/Arch)
    if command -v pacman &>/dev/null; then
        PKGS=""
        $HAS_UNRAR || PKGS="${PKGS} unrar"
        $HAS_7Z || PKGS="${PKGS} p7zip"
        if [[ -n "${PKGS}" ]]; then
            echo "Installing:${PKGS}"
            sudo pacman -S --noconfirm ${PKGS} 2>/dev/null || echo "pacman install failed (filesystem may be read-only)"
        fi
    # Try apt (Debian/Ubuntu)
    elif command -v apt-get &>/dev/null; then
        PKGS=""
        $HAS_UNRAR || PKGS="${PKGS} unrar"
        $HAS_7Z || PKGS="${PKGS} p7zip-full"
        if [[ -n "${PKGS}" ]]; then
            echo "Installing:${PKGS}"
            sudo apt-get install -y ${PKGS} 2>/dev/null || echo "apt install failed"
        fi
    else
        echo "No supported package manager found. Please install unrar and p7zip manually."
    fi

    # Verify
    command -v unrar &>/dev/null && echo "unrar: OK" || echo "unrar: NOT FOUND (rar extraction will not work)"
    (command -v 7z &>/dev/null || command -v 7za &>/dev/null) && echo "7z: OK" || echo "7z: NOT FOUND (7z extraction will not work)"
}

if [ "$1" == "uninstall" ]; then
    echo "Uninstalling dependencies: itch.io extension"
    uninstall
else
    echo "Installing dependencies: itch.io extension"
    install
fi
