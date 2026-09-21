# Third-party notices

## BepInEx

The installer downloads and verifies the official BepInEx Unity Mono Windows x64 build `6.0.0-be.788+5b766a3`.

- Project: https://github.com/BepInEx/BepInEx
- Release build: https://builds.bepinex.dev/projects/bepinex_be
- License: LGPL-2.1 (`LICENSES/BepInEx-LGPL-2.1.txt`)

## UnityDoorstop

`winhttp.dll` and `doorstop_config.ini` are downloaded as part of the BepInEx Unity Mono distribution.

- Project: https://github.com/NeighTools/UnityDoorstop
- License: LGPL-2.1 (`LICENSES/UnityDoorstop-LGPL-2.1.txt`)

## Other BepInEx bundled components

The BepInEx build also bundles Harmony, HarmonyX, and Mono.Cecil. Their license texts are included in `LICENSES`.

## Scavland Melon compatibility host

The installer downloads the official MelonLoader 0.7.3 archive from LavaGang, then applies the Scavland compatibility `MelonLoader.dll` and `ScavlandMelonHost.dll`. The native MelonLoader bootstrap files are intentionally omitted because the combined runtime uses BepInEx's UnityDoorstop bootstrap.
