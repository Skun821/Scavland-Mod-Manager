# Scavland Mod Manager v0.1.0

Initial public release of the Scavland BepInEx / MelonLoader bridge runtime.

## Included

- BepInEx 6 Unity Mono runtime for Scavland.
- `ScavlandMelonHost`, the BepInEx-hosted MelonLoader bridge.
- A pinned download of the official MelonLoader 0.7.3 x64 package.
- Backup, restore, status and log-diagnosis commands.
- Complete corresponding source and third-party notices.

## Installation

Download `ScavlandModManager-0.1.0.zip`, extract it into the Scavland game
folder, then run `ScavlandModManager.cmd`.

The manager backs up the eleven Managed compatibility DLLs before applying the
official MelonLoader compatibility versions. It never distributes Scavland game
assemblies, user configuration, saves or third-party MODs.

## Compatibility

BepInEx MODs belong in `BepInEx/plugins`. Melon MODs belong in `Mods` or
`Plugins`. The bridge provides a tested loader path, not a guarantee that every
third-party Melon MOD will work. See `COMPATIBILITY.md` and use
`ScavlandModManager.cmd -Action Diagnose` after a failed launch.
