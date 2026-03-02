# Decky GameVault

> **A community fork of [Junk-Store](https://github.com/ebenbruyns/junkstore) — an open and extensible multi-store game launcher for Steam Deck.**

## About

GameVault lets you access non-Steam games directly from Game Mode. No Desktop Mode required.

Built on the Junk-Store framework, this fork adds community-built store integrations and quality-of-life features on top of the original Epic Games support.

## Store Integrations

| Store | Backend | Origin |
|-------|---------|--------|
| **Epic Games** | Legendary | Original (upstream) |
| **GOG** | lgogdownloader / gogdl | Community extension |
| **Amazon Games** | Nile | Community extension |
| **itch.io** | itch.io API | Community extension |

### A Note on GOG

The official Junk-Store project offers its own GOG integration via [Patreon](https://www.patreon.com/junkstore) or [Ko-fi](https://ko-fi.com/junkstore). The GOG extension in this fork is a **separate, independently-built** implementation. If you want the officially supported GOG experience, consider supporting the original project.

### Setup Notes

- **Epic Games** — Works out of the box. Log in from the plugin.
- **GOG** — Install dependencies from the About menu before use. Requires a keyboard for browser-based login.
- **Amazon Games** — Install dependencies from the About menu before use. Requires a keyboard to paste the redirect URL during login.
- **itch.io** — Log in with your itch.io API key. Access your purchased and claimed games.

## Features

### Original (from Junk-Store)

These features are part of the upstream framework that GameVault is built on:

- **Epic Games Store** — Full integration via Legendary (install, update, verify, repair)
- **EOS Overlay Management** — Install, update, and remove the Epic Online Services overlay
- **Per-Game Launch Configuration** — Proton version selection, environment variables, FPS limiting, FSR, ESYNC/FSYNC toggles via the QAM
- **Platform Config Editor** — Edit game INI/config files directly from Game Mode
- **Executable Runner** — Run executables (EXE, BAT, MSI) from game install folders
- **Protontricks Integration** — Launch Proton Tricks GUI for manual Proton fixes
- **UMU ID Management** — Update UMU IDs for compatibility tracking
- **Registry Fix** — Apply Windows registry fixes via Proton (Epic)
- **Dependency Installer** — One-click install for Proton EasyAntiCheat Runtime and BattlEye Runtime
- **Import/Move Games** — Manage game storage locations
- **Custom Backend Support** — Extensible architecture for community store scripts
- **Developer Mode** — Toggle developer tools and log viewer
- **Achievements** — Hidden unlockable achievements

### Community Additions (GameVault Fork)

These features were added by the community fork:

- **GOG Store Extension** — Full game management, browser-based login, cloud save sync
- **Amazon Games Extension** — Full game management via Nile backend
- **itch.io Extension** — Access purchased and claimed games via API key
- **SteamGridDB Artwork Fallback** — Automatically fills missing game artwork from SteamGridDB. Set your API key in any store's tab config (gear icon). Images are cached for one-time lookup per game.
- **Cloud Save Sync (Epic & GOG)** — Upload and download save files, with per-game auto-sync toggle
- **GE-Proton Installer** — One-click download and install of the latest GE-Proton from the Dependencies tab
- **Proton Fixes Lookup** — Look up known fixes for any installed game from the [umu-protonfixes](https://github.com/Open-Wine-Components/umu-protonfixes) database. Falls back to Steam fixes via UMU ID when store-specific fixes aren't available.
- **Auto-Apply Proton Fixes** — One-click button to automatically apply known environment variable fixes to a game's launch configuration
- **Storage Management** — View total disk usage across all stores, per-store breakdown, free disk space, and installed games sorted by size from the About page's Storage tab
- **Batch Install Queue** — Select multiple games from a store grid and queue them for sequential download and installation
- **Game Update Detection** — Automatically checks for available updates when viewing an installed game (Epic, GOG, Amazon). Shows an "Update Available" indicator on the play button.
- **Improved GOG Uninstall** — Properly cleans up gogdl manifest state so games can be reinstalled without manual intervention

## Installing

1. Download the latest release zip from the [Releases](https://github.com/Starkka15/junkstore/releases) page
2. Transfer to your Steam Deck
3. Extract to `~/homebrew/plugins/GameVault/`
4. Restart Decky Loader

## Credits

### Original Project
- [Junk-Store](https://github.com/ebenbruyns/junkstore) by Eben Bruyns
- Eben Bruyns (junkrunner) - Software Sorcerer
- Annie Ryan (mrs junkrunner) - Order Oracle
- Jesse Bofill - Visual Virtuoso
- Tech - Glitch Gladiator
- Logan (Beebles) - UI Developer

### Community Fork
- Starkka15 - GOG, Amazon, itch.io extensions, cloud save sync, SteamGridDB integration, GE-Proton installer, protonfixes lookup/apply, storage management, batch install queue, update detection

## Links

- Original project: [github.com/ebenbruyns/junkstore](https://github.com/ebenbruyns/junkstore)
- Official Junk-Store Discord: [![Chat](https://img.shields.io/badge/chat-on%20discord-7289da.svg)](https://discord.gg/Dy7JUNc44A)
