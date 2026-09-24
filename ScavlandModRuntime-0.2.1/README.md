# Scavland Mod Runtime 0.2.1

Scavland Mod Runtime installs an **unmodified official BepInEx 6 core** and the Scavland Melon compatibility host for the current Steam build of Scavland. It does **not** replace or edit anything in `Scavland_Data\Managed`.

Tested with Scavland Steam build `25339586` (2026-09-24).

## Install

1. Extract this ZIP anywhere.
2. Run `Install-Scavland-Mod-Runtime.cmd`.
3. Enter the Scavland game folder — the folder containing `Scavland.exe`.
4. Start Scavland normally from Steam.

The installer backs up an existing `BepInEx\core` folder before it installs its official BepInEx core. It retains your BepInEx plugins, BepInEx configuration, and save data. It never modifies `Scavland_Data` or the game's managed DLLs.

## Where mods go

| Mod type | Folder |
| --- | --- |
| BepInEx plugin | `Scavland\BepInEx\plugins` |
| Compatible MelonLoader MOD | `Scavland\Mods` |
| Compatible MelonLoader plugin | `Scavland\Plugins` |
| Melon dependency library | `Scavland\UserLibs` |

The included compatibility host is verified to discover and load compatible Melon MOD DLLs from these folders. It is not a full MelonLoader runtime: mods that depend on unsupported Harmony, MonoMod, native hooks, or missing .NET APIs may still need a dedicated compatibility update.

## Compatibility notes

- Windows x64 Unity Mono only.
- This package includes BepInEx 6.0.0-be.788+5b766a3 without source changes.
- This package includes the 0.2.1 compatibility host, which preserves MelonLoader preference load/save callbacks and creates the loader config on first launch.
- The installer deliberately does not bundle any game files, game DLL replacements, or third-party game mods.

## Licenses and source

BepInEx and UnityDoorstop are distributed under LGPL-2.1. License texts and notices are in `LICENSES` and `THIRD_PARTY_NOTICES.md`. Official source and releases:

- https://github.com/BepInEx/BepInEx
- https://github.com/NeighTools/UnityDoorstop
- https://builds.bepinex.dev/projects/bepinex_be
