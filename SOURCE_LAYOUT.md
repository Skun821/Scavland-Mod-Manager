# Published source layout

- `bridge/ScavlandMelonHost` — this project's BepInEx bridge-plugin source.
- `bridge/MelonLoader-ScavlandCompat` — complete MelonLoader 0.7.3 source,
  including the four Scavland compatibility changes.
- `third_party/BepInEx-6.0.0-be.788` — unmodified BepInEx source at the exact
  commit used by the runtime payload.

Generated archives, downloaded build inputs, Scavland game files, user MODs,
saves, logs and configuration are excluded by `.gitignore`.
