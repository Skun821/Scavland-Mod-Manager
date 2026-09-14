# Release checklist

Do not publish the `-dev` artifacts.

- [ ] Publish the complete corresponding source on GitHub: this manager,
      `ScavlandMelonHost`, and the full modified MelonLoader v0.7.3 source tree.
- [ ] State the BepInEx source revision `5b766a3b7f6c164d4798924a93f3acf4db769d06`
      and publish the payload build inputs/instructions required by LGPL-2.1.
- [ ] Publish the runtime payload as an immutable GitHub Release asset.
- [ ] Calculate its SHA-256 and replace both `REPLACE_OWNER` and the hash in
      `manager.manifest.json`.
- [ ] Build a fresh bootstrap ZIP only after the manifest has its final URL.
- [ ] Build and publish the matching source ZIP using
      `Build-ScavlandSourceRelease.ps1`.
- [ ] Confirm that neither archive contains `Scavland_Data`, game DLLs, user
      saves/configuration/logs, nor third-party MODs.
- [ ] Test Install, Launch, Status and Restore against the current Steam build
      in a disposable test installation.
- [ ] Describe supported loader versions and tested MODs. Do not claim that all
      MelonLoader MODs are compatible.

The release can download and locally apply the eleven official MelonLoader
compatibility assemblies after making a backup. It must not bundle or upload
those replacement game-directory assemblies as part of its own payload.
