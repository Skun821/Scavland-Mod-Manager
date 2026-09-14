# Bridge compatibility status

## Confirmed in Scavland

- BepInEx 6 Unity Mono runtime starts and loads BepInEx plugins.
- The self-made `ScavlandMelonHost` loads the modified MelonLoader 0.7.3
  runtime and dispatches basic Melon lifecycle callbacks.
- The manager installs the official MelonLoader compatibility BCL files only
  after backing up the eleven files it replaces, and restores that backup.

## Not a universal compatibility promise

The bridge can load a Melon DLL, but individual mods may also need APIs that
Scavland's compact Unity Mono runtime does not provide. The known next blocker
is Harmony/MonoMod code that calls unavailable reflection members such as
`AssemblyName.ProcessorArchitecture`. A manager install cannot safely invent
those runtime features.

The bridge should grow through a tested compatibility matrix: reproduce one
specific MOD failure, identify the missing API or loader behavior, make the
smallest bridge-side fix, then regression-test it with the previous working
MODs. Native hooks, anti-loader checks, and game-version-specific patches are
separate compatibility classes.

Run `ScavlandModManager.cmd -Action Diagnose` after a failed launch. It reads
existing loader logs and recognizes the current known signatures without
changing game files.
