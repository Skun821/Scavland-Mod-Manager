# Scavland bridge changes

The bridge is based on MelonLoader v0.7.3, upstream commit `982ed99`.

Modified MelonLoader source files:

- `MelonLoader/Core.cs` — adds the Scavland compatibility initialization and
  startup entries used by `ScavlandMelonHost`.
- `MelonLoader/MelonUtils.cs` — avoids a stripped-runtime stack-trace API.
- `MelonLoader/Melons/MelonBase.cs` — bypasses runtime facilities unavailable
  in Scavland's Unity Mono build.
- `MelonLoader/Utils/MelonEnvironment.cs` — derives the game process context
  without `Process.MainModule`.

`ScavlandMelonHost` is a BepInEx plugin that loads the modified MelonLoader
assembly, supplies the bootstrap adapter, loads `Mods`, `Plugins`, and
`UserLibs`, then forwards Unity lifecycle events to registered Melon mods.

This is deliberately a compatibility layer, not a promise that every Melon
mod is compatible. Mods that use unsupported native hooks, a loader-integrity
check, or unavailable runtime APIs require a specific compatibility fix.
