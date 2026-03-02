# Decky GameVault

> **A community fork of [Junk-Store](https://github.com/ebenbruyns/junkstore) — an open and extensible multi-store game launcher for Steam Deck.**

## About

GameVault lets you access non-Steam games directly from Game Mode. No Desktop Mode required.

Built on the Junk-Store framework, this fork adds community-built store integrations for GOG, Amazon Games, and itch.io alongside the existing Epic Games support.

## Store Integrations

| Store | Backend | Status |
|-------|---------|--------|
| **Epic Games** | Legendary | Included upstream |
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

## Additional Features

### SteamGridDB Artwork Fallback
- Automatically fills missing game artwork from SteamGridDB
- Set your API key in any store's tab config (gear icon)
- Images are cached — one-time lookup per game

### Cloud Save Sync (Epic & GOG)
- Upload and download save files for supported games
- Per-game auto-sync toggle
- Access from the gear menu on any installed game

### Per-Game Launch Configuration
- Proton version selection and environment variable tweaks
- FPS limiting, FSR, ESYNC/FSYNC toggles via the QAM
- Run executables directly from game folders
- Platform config file editor (INI editor)

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
- Starkka15 - GOG, Amazon, itch.io extensions, cloud save sync, SteamGridDB integration

## Links

- Original project: [github.com/ebenbruyns/junkstore](https://github.com/ebenbruyns/junkstore)
- Official Junk-Store Discord: [![Chat](https://img.shields.io/badge/chat-on%20discord-7289da.svg)](https://discord.gg/Dy7JUNc44A)
