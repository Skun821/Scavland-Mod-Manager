# Reproducible release build

The release consists of two assets:

1. `ScavlandModManager.zip` — the bootstrap scripts, manifest, notices and
   source links.
2. `Scavland-BepInEx-Runtime-<version>.zip` — BepInEx runtime files,
   `ScavlandMelonHost.dll`, and the modified `MelonLoader.dll` only.

The runtime archive must never contain `Scavland_Data`, `Assembly-CSharp.dll`,
game logs, user configuration, or third-party MODs.

Build the user-facing bootstrap ZIP only after its manifest contains the final
GitHub Release URL and SHA-256:

```powershell
.\Build-ScavlandModManagerZip.ps1 -OutputZip '.\artifacts\ScavlandModManager-0.1.2.zip'
```

Build and publish the matching source archive with the runtime payload:

```powershell
.\Build-ScavlandSourceRelease.ps1 `
  -BepInExSource '<BepInEx source at 5b766a3...>' `
  -MelonLoaderSource '<modified MelonLoader source>' `
  -MelonHostSource '<ScavlandMelonHost source>' `
  -OutputZip '.\artifacts\ScavlandModManager-Source-0.1.2.zip'
```

Build the bridge projects first, then create the runtime payload:

```powershell
dotnet build '<ScavlandMelonHost.csproj>' -c Release `
  -p:ScavlandGamePath='C:\Program Files (x86)\Steam\steamapps\common\Scavland'

.\Build-ScavlandRuntimePayload.ps1 `
  -BepInExRoot '<Scavland quiet-logging patched BepInEx 6 runtime root>' `
  -BridgeDll '<ScavlandMelonHost.dll>' `
  -CustomMelonLoaderDll '<modified MelonLoader.dll>' `
  -BepInExLicense '<BepInEx LICENSE>' `
  -MelonLoaderLicense '<MelonLoader LICENSE.md>' `
  -MelonLoaderNotice '<MelonLoader NOTICE.txt>' `
  -OutputZip '.\artifacts\Scavland-BepInEx-Runtime-0.1.2.zip'
```

Calculate the SHA-256 of the completed archive and put it in
`manager.manifest.json` before publishing. Replace the manifest's placeholder
runtime URL with the immutable GitHub Release asset URL. The installer rejects
placeholder or unpinned artifacts.

Before publishing, include the exact bridge source, the modified MelonLoader
source, source/build instructions for the BepInEx runtime, `THIRD_PARTY_NOTICES.md`,
`BRIDGE_CHANGES.md`, and the applicable LGPL-2.1 and Apache-2.0 license texts.
