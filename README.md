# Junk Store Decky Plugin (Community Fork)

> **This is a community fork of [Junk-Store](https://github.com/ebenbruyns/junkstore) with additional store integrations and features.**

## About

Junk-Store is an open and extensible launcher framework for Steam Deck that lets you access non-Steam games directly from Game Mode. No Desktop Mode required.

This fork extends the original with community-built store integrations, bringing GOG, Amazon Games, and itch.io support alongside the existing Epic Games integration.

## Store Integrations

| Store | Backend | Status |
|-------|---------|--------|
| **Epic Games** | Legendary | Included upstream |
| **GOG** | lgogdownloader / gogdl | Community extension |
| **Amazon Games** | Nile | Community extension |
| **itch.io** | itch.io API | Community extension |

### Setup Notes

- **Epic Games** — Works out of the box. Log in from the plugin.
- **GOG** — Install dependencies from the About menu before use. Requires a keyboard for browser-based login.
- **Amazon Games** — Install dependencies from the About menu before use. Requires a keyboard to paste the redirect URL during login.
- **itch.io** — Log in with your itch.io API key. Access your purchased and claimed games.

## Additional Features

### Cloud Save Sync (Epic & GOG)
- Upload and download save files for supported games
- Per-game auto-sync toggle — automatically sync saves when launching/closing a game
- Access from the gear menu on any installed game

### Per-Game Launch Configuration
- Proton version selection and environment variable tweaks
- FPS limiting, FSR, ESYNC/FSYNC toggles via the QAM
- Run executables directly from game folders
- Platform config file editor (INI editor)

## Installing

This fork is not available on the Decky store. To install:

1. Download the latest release zip from the [Releases](https://github.com/Starkka15/junkstore/releases) page
2. Transfer to your Steam Deck
3. Extract to `~/homebrew/plugins/Junk-Store/`
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
- Starkka15 - GOG, Amazon, itch.io extensions, cloud save sync

## Links

- Original project: [github.com/ebenbruyns/junkstore](https://github.com/ebenbruyns/junkstore)
- Official Junk-Store Discord: [![Chat](https://img.shields.io/badge/chat-on%20discord-7289da.svg)](https://discord.gg/Dy7JUNc44A)
- Official wiki: [wiki.junkstore.xyz](https://wiki.junkstore.xyz)
