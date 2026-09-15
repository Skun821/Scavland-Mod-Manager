# Scavland Mod Manager

Open-source bootstrap runtime for the Windows x64 Steam edition of Scavland.

It installs a Scavland-tested BepInEx runtime, installs the
Scavland Melon bridge, downloads the pinned official MelonLoader release,
backs up the eleven core compatibility assemblies, and can restore those
assemblies later. The full compatibility BCL is included specifically so that
normal Harmony, MonoMod RuntimeDetour and missing managed-API dependencies can
run under the hosted MelonLoader path.

This repository never contains Scavland game binaries or third-party MOD DLLs.

## Compatibility contract

`BepInEx/plugins` contains BepInEx MODs. `Mods` and `Plugins` contain Melon
MODs/plugins. The manager reports what it installed, but does not promise that
an arbitrary third-party MOD will work: native hooks, obsolete Melon APIs,
external native DLLs and MOD-specific loader checks need individual
compatibility work.

After a failed launch, run the read-only diagnostic command:

```powershell
.\ScavlandModManager.cmd -Action Diagnose
```

See `COMPATIBILITY.md` for the tested scope and current bridge limitations.

## Development use

Create a release manifest with immutable HTTPS URLs and SHA-256 hashes for:

1. A Scavland runtime payload containing the tested BepInEx files and
   `ScavlandMelonHost.dll`.
2. The official `MelonLoader.x64.zip` release.

Then run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-ScavlandModManager.ps1 -Action Install -GamePath 'C:\Program Files (x86)\Steam\steamapps\common\Scavland'
```

The installer refuses URLs without a pinned SHA-256 hash. It creates a backup
before replacing any core compatibility assembly. `-Action Restore` restores
only those backed-up core assemblies; it deliberately leaves user MOD files
alone.

For a release-build verification without network access, pass both local
archives. They are still checked against the manifest hashes:

```powershell
.\Install-ScavlandModManager.ps1 -Action Install -GamePath '<test game folder>' `
  -RuntimeArchive '.\Scavland-BepInEx-Runtime-0.1.2.zip' `
  -MelonLoaderArchive '.\MelonLoader.x64.zip'
```

## Distribution

Publish the runtime payload and this bootstrap as GitHub Release assets. Include
the complete corresponding source, build instructions and third-party notices
for every BepInEx / MelonLoader derivative used in the payload.
