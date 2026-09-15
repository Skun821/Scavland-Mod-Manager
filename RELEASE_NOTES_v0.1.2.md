# Scavland Mod Manager v0.1.2

## Quiet startup logging

- Suppresses only two known non-fatal BepInEx startup messages caused by
  Scavland's stripped Unity logging APIs:
  - `Unable to start Unity log writer`
  - `Unity log forwarding is unavailable ...`
- Keeps BepInEx file logging, console logging, plugin loading, and all real
  MOD errors enabled.
- The corresponding modified BepInEx source is included in the matching source
  archive, together with the change description and LGPL-2.1 notice.
