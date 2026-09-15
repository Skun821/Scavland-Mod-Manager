# Scavland Mod Manager v0.1.1

## Runtime compatibility update

- Replaces the previous Scavland-specific BepInEx runtime composition with an
  unmodified BepInEx 6 Unity Mono runtime plus the official full MelonLoader
  compatibility BCL.
- Keeps `System.Runtime.CompilerServices.Unsafe.dll` untouched.
- Keeps the ScavlandMelonHost and the modified MelonLoader 0.7.3 bridge.
- Adds an isolated game-launch verification for both a real Harmony patch and
  a real MonoMod RuntimeDetour.

## Scope

This release targets normal managed Melon MODs which require Harmony,
MonoMod RuntimeDetour or standard .NET Framework APIs absent from Scavland's
original compact BCL. It does not claim compatibility with MODs that require
native hooks, an anti-loader bypass, unsupported legacy APIs or a specific
game build.
