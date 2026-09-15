# Third-party notices

## BepInEx

The runtime payload contains BepInEx 6 Unity Mono runtime files, version
`6.0.0-be.788` (commit `5b766a3b7f6c164d4798924a93f3acf4db769d06`) with a
minimal Scavland quiet-logging patch. It suppresses only the two non-fatal
messages emitted when Scavland's stripped Unity APIs prevent optional Unity-log
forwarding. The complete modified source and change description are included
with the matching source release.
BepInEx is licensed under GNU LGPL v2.1 or later.

- Source: https://github.com/BepInEx/BepInEx
- License: https://github.com/BepInEx/BepInEx/blob/master/LICENSE

For every published binary release, this project will publish the exact payload
build inputs, build script, BepInEx source revision, changes to BepInEx (if
any), and the complete corresponding source required by LGPL-2.1.

## MelonLoader

The installer downloads the official MelonLoader x64 archive from LavaGang and
the runtime payload includes the Scavland-specific replacement `MelonLoader.dll`.
MelonLoader is licensed under Apache License 2.0.

- Source: https://github.com/LavaGang/MelonLoader
- License: https://github.com/LavaGang/MelonLoader/blob/master/LICENSE.md
- Upstream used for this bridge: v0.7.3 (`982ed99`)

The source release must include the modified MelonLoader source tree, its
Apache-2.0 license and NOTICE file, plus a concise list of the Scavland bridge
changes. No Scavland game DLL is included or redistributed by this project.

## ScavlandMelonHost

`ScavlandMelonHost.dll` is this project's BepInEx bridge plugin. Its source and
build instructions are published with this project under the project license.
