#!/usr/bin/env bash
DOWNLOAD_LOCATION_GOGDL="https://github.com/ebenbruyns/gogdl-flatpak/releases/latest/download/gogdl.flatpak"

function download_and_install() {
    cd /tmp
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --user install flathub org.gnome.Platform//49 -y

    wget -O gogdl.flatpak "$DOWNLOAD_LOCATION_GOGDL" || { echo "ERROR: Failed to download gogdl"; return 1; }

    flatpak --user install "gogdl.flatpak" -y
    rm -f gogdl.flatpak

    # Native emulators for DOSBox/ScummVM GOG games
    flatpak --user install flathub io.github.dosbox-staging -y || true
    flatpak --user install flathub org.scummvm.ScummVM -y || true

    # Grant filesystem access so emulators can reach game files anywhere
    flatpak override --user --filesystem=host io.github.dosbox-staging 2>/dev/null || true
    flatpak override --user --filesystem=host org.scummvm.ScummVM 2>/dev/null || true
}

function install() {
    if flatpak list | grep -q "com.github.heroic_games_launcher.heroic-gogdl"; then
        echo "gogdl flatpak is installed, removing and reinstalling"
        flatpak uninstall com.github.heroic_games_launcher.heroic-gogdl -y
    fi

    download_and_install
}

function uninstall() {
    echo "Uninstalling flatpaks"
    if flatpak list | grep -q "com.github.heroic_games_launcher.heroic-gogdl"; then
        flatpak uninstall com.github.heroic_games_launcher.heroic-gogdl -y
    fi
    if flatpak list | grep -q "io.github.dosbox-staging"; then
        flatpak uninstall io.github.dosbox-staging -y
    fi
    if flatpak list | grep -q "org.scummvm.ScummVM"; then
        flatpak uninstall org.scummvm.ScummVM -y
    fi
    flatpak uninstall --unused -y
}

if [ "$1" == "uninstall" ]; then
    echo "Uninstalling dependencies: GOG extension"
    uninstall
else
    echo "Installing dependencies: GOG extension"
    install
fi
