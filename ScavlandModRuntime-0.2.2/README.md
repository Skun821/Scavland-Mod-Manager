# Scavland Mod Runtime 0.2.2

This installer downloads the official BepInEx 6 Unity Mono package and the official MelonLoader 0.7.3 package, verifies both archives, and then applies the Scavland compatibility layer. It does not replace or edit anything in `Scavland_Data\Managed`.

## Install

1. Extract this package into the Scavland game folder, or anywhere convenient.
2. Run `Install-Scavland-Mod-Runtime.cmd`.
3. The installer detects the game folder when the package is inside the game folder. Otherwise, enter the folder containing `Scavland.exe`.
4. Start Scavland normally through Steam.

The installer downloads and verifies both official runtimes before changing the game installation. Existing BepInEx plugins, configuration, saves, and existing runtime folders are backed up or preserved as applicable.

## Where mods go

| Mod type | Folder |
| --- | --- |
| BepInEx plugin | `Scavland\BepInEx\plugins` |
| Compatible MelonLoader MOD | `Scavland\Mods` |
| Compatible MelonLoader plugin | `Scavland\Plugins` |
| MelonLoader dependency library | `Scavland\UserLibs` |

The installer first installs the official MelonLoader managed runtime, then replaces only `MelonLoader\net472\MelonLoader.dll` with the Scavland compatibility build and installs `ScavlandMelonHost.dll` under BepInEx. The native MelonLoader bootstrap (`version.dll` / `dobby.dll`) is not installed because BepInEx owns the Unity bootstrap.

## Verified official runtimes

- BepInEx `6.0.0-be.788+5b766a3`
- MelonLoader `0.7.3`

Both downloads are checked with SHA-256 before installation.

## Logs

The BepInEx console is enabled by the installer. The file log is:

```text
Scavland\BepInEx\LogOutput.log
```

## Important

- Do not copy MOD DLLs into `Scavland_Data\Managed`.
- Do not install a second native MelonLoader bootstrap alongside this combined setup.
- This package contains no Scavland game files, managed DLL replacements, saves, or third-party MODs.

## Licenses

Scavland runtime components are released under the MIT License. BepInEx, MelonLoader, UnityDoorstop, and bundled dependencies retain their own licenses. See `LICENSES` and `THIRD_PARTY_NOTICES.md`.
