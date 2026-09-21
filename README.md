# Scavland BepInEx + MelonLoader Bridge

This repository publishes the `ScavlandModRuntime-0.2.0` installer for the
Windows x64 Steam edition of Scavland.

**Display name:** Scavland BepInEx + MelonLoader Bridge

The installer downloads the official BepInEx Unity Mono runtime and the
official MelonLoader 0.7.3 archive, verifies both downloads, and then applies
the Scavland compatibility files so BepInEx and compatible MelonLoader MODs
can run together. It does not include the BepInEx source tree,
the MelonLoader source tree, Scavland game files, `Assembly-CSharp.dll`, or
user MODs.

## Installation

1. Open the Scavland game folder, the folder containing `Scavland.exe`.
2. Extract the `ScavlandModRuntime-0.2.0` package inside the game folder.
3. Open the extracted package folder and run
   `Install-Scavland-Mod-Runtime.cmd`.
4. The installer detects the parent Scavland folder automatically. If it does
   not, enter the path containing `Scavland.exe`.
5. Start Scavland normally through Steam.

The installer installs the official runtime first, then applies the Scavland
compatibility layer.

## MOD installation locations

- BepInEx MODs: `Scavland/BepInEx/plugins/`
- MelonLoader MODs: `Scavland/Mods/`

## Console logs

The packaged configuration enables the BepInEx console window:

```ini
[Logging.Console]
Enabled = true
```

Runtime logs are also written to:

```text
Scavland/BepInEx/LogOutput.log
```

## Package contents

The complete installer is in [`ScavlandModRuntime-0.2.0/`](ScavlandModRuntime-0.2.0/).

- `Install-Scavland-Mod-Runtime.cmd`: user-facing installer
- `Install-Scavland-Mod-Runtime.ps1`: download, verification, and installation logic
- `Runtime/ScavlandMelonLoader.dll`: Scavland compatibility build applied after the official download
- `Runtime/BepInEx/plugins/ScavlandMelonHost.dll`: BepInEx bridge for compatible MelonLoader MODs
- `README.md`, `LICENSE`, and `THIRD_PARTY_NOTICES.md`: installation and legal notices

Do not copy the DLLs into `Scavland_Data/Managed`. Do not install the native
MelonLoader bootstrap (`version.dll` or `dobby.dll`) alongside this combined
BepInEx setup.

## License

Original Scavland runtime components in this repository are released under
the MIT License. See [LICENSE](LICENSE). BepInEx and MelonLoader remain
separate upstream projects and are downloaded from their official sources by
the installer; their notices are documented in the package's
`THIRD_PARTY_NOTICES.md`.
