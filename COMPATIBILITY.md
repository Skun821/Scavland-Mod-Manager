# Bridge compatibility status

## Confirmed in Scavland

- BepInEx 6 Unity Mono runtime starts and loads BepInEx plugins.
- The self-made `ScavlandMelonHost` loads the modified MelonLoader 0.7.3
  runtime and dispatches basic Melon lifecycle callbacks.
- The manager installs the official MelonLoader compatibility BCL files only
  after backing up the eleven files it replaces, and restores that backup.
- A full-BCL, unmodified-BepInEx isolated game launch loaded a Melon MOD which
  applied a real Harmony patch (`1 -> 2`) and a real MonoMod RuntimeDetour
  (`3 -> 4`). This is the manager's baseline runtime composition.

## Not a universal compatibility promise

The bridge can load a Melon DLL, but it cannot guarantee arbitrary third-party
MOD behavior. The full compatibility BCL specifically targets normal
Harmony/MonoMod and missing managed-API dependencies. Native hooks,
anti-loader checks, obsolete Melon APIs, external native DLLs and
game-version-specific patches still need individual compatibility work.

The bridge should grow through a tested compatibility matrix: reproduce one
specific MOD failure, identify the missing API or loader behavior, make the
smallest bridge-side fix, then regression-test it with the previous working
MODs. Native hooks, anti-loader checks, and game-version-specific patches are
separate compatibility classes.

Run `ScavlandModManager.cmd -Action Diagnose` after a failed launch. It reads
existing loader logs and recognizes the current known signatures without
changing game files.
