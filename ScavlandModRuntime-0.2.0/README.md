# Scavland BepInEx + MelonLoader Bridge 0.2.0

Scavland BepInEx + MelonLoader Bridge downloads the official BepInEx 6 Unity Mono package and the official MelonLoader 0.7.3 package, verifies both archives, and then applies the Scavland compatibility layer so BepInEx and compatible MelonLoader MODs can run together. It does **not** replace or edit anything in `Scavland_Data\Managed`.

Tested with Scavland Steam build `25339586` (2026-09-16).

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

The official MelonLoader managed runtime is installed first. The package then replaces only `MelonLoader\net472\MelonLoader.dll` with the Scavland compatibility build and installs `ScavlandMelonHost.dll` under BepInEx. The native MelonLoader bootstrap (`version.dll` / `dobby.dll`) is deliberately not installed because BepInEx owns the Unity bootstrap for the combined setup.

## Compatibility notes

- Windows x64 Unity Mono only.
- The installer downloads BepInEx 6.0.0-be.788+5b766a3 from the official BepInEx build service and verifies its SHA-256.
- The installer downloads MelonLoader 0.7.3 from the official LavaGang release and verifies its SHA-256.
- The older `Scavland Mod Runtime 0.1.1` is a Legacy package for prior Scavland builds. Do not mix its custom BepInEx DLL with this package.
- The installer deliberately does not bundle any game files, game DLL replacements, or third-party game mods.

## Licenses and source

BepInEx and UnityDoorstop are distributed under LGPL-2.1. License texts and notices are in `LICENSES` and `THIRD_PARTY_NOTICES.md`. Official source and releases:

- https://github.com/BepInEx/BepInEx
- https://github.com/NeighTools/UnityDoorstop
- https://builds.bepinex.dev/projects/bepinex_be
