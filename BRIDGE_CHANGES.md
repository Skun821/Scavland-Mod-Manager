# Scavland bridge changes

The bridge is based on MelonLoader v0.7.3, upstream commit `982ed99`.

Modified MelonLoader source files:

- `MelonLoader/Core.cs` adds the Scavland compatibility initialization and
  startup entries used by `ScavlandMelonHost`.
- `MelonLoader/MelonUtils.cs` provides a safe stack-trace fallback.
- `MelonLoader/Melons/MelonBase.cs` adapts host-owned runtime facilities.
- `MelonLoader/Utils/MelonEnvironment.cs` derives the game process context
  without depending on the native Melon bootstrap process.

`ScavlandMelonHost` is a BepInEx plugin that loads the modified MelonLoader
assembly, supplies the bootstrap adapter, loads `Mods`, `Plugins`, and
`UserLibs`, then forwards Unity lifecycle events to registered Melon mods.

The manager runtime pairs this host with the official full compatibility BCL
and BepInEx 6. The BepInEx source has one Scavland-specific quiet-logging
change: when Scavland's stripped Unity APIs make Unity-log forwarding
unavailable, it does not emit the two non-fatal startup messages. Standard
BepInEx file/console logging and MOD error logging are unchanged. This makes
standard managed dependencies such as Harmony and MonoMod RuntimeDetour
available. It remains a compatibility layer, not a promise that every Melon
mod is compatible: unsupported native hooks, loader-integrity checks and
game-version-specific patches require a specific compatibility fix.
