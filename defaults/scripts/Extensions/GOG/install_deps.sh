#!/usr/bin/env bash
DOWNLOAD_LOCATION_GOGDL="https://github.com/ebenbruyns/gogdl-flatpak/releases/latest/download/gogdl.flatpak"

function download_and_install() {
    cd /tmp
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --user install flathub org.gnome.Platform//49 -y

    wget "$DOWNLOAD_LOCATION_GOGDL"

    flatpak --user install "gogdl.flatpak" -y
    rm -f gogdl.flatpak
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
    flatpak uninstall --unused -y
}

if [ "$1" == "uninstall" ]; then
    echo "Uninstalling dependencies: GOG extension"
    uninstall
else
    echo "Installing dependencies: GOG extension"
    install
fi
