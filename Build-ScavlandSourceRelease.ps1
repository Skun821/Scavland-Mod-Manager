[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $BepInExSource,
    [Parameter(Mandatory = $true)] [string] $MelonLoaderSource,
    [Parameter(Mandatory = $true)] [string] $MelonHostSource,
    [Parameter(Mandatory = $true)] [string] $OutputZip
)

$ErrorActionPreference = 'Stop'
foreach ($path in @($BepInExSource, $MelonLoaderSource, $MelonHostSource)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required source directory was not found: $path" }
}

function Copy-SourceTree([string] $Source, [string] $Destination) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    & robocopy $Source $Destination /E /XD .git bin obj Output artifacts vendor-cache .vs /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy failed while staging source: $Source (exit $LASTEXITCODE)" }
}

function Copy-ManagerSource([string] $Source, [string] $Destination) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    & robocopy $Source $Destination /E /XD .git bin obj Output artifacts vendor-cache toolchain test-evidence .vs bridge third_party /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy failed while staging manager source: $Source (exit $LASTEXITCODE)" }
}

$stage = Join-Path ([IO.Path]::GetTempPath()) ('ScavlandSourceRelease-' + [Guid]::NewGuid().ToString('N'))
try {
    $release = Join-Path $stage 'ScavlandModManager-Source'
    Copy-ManagerSource $PSScriptRoot (Join-Path $release 'ScavlandModManager')
    Copy-SourceTree $MelonHostSource (Join-Path $release 'ScavlandMelonHost')
    Copy-SourceTree $MelonLoaderSource (Join-Path $release 'MelonLoader-ScavlandCompat')
    Copy-SourceTree $BepInExSource (Join-Path $release 'BepInEx-6.0.0-be.788')
    @'
# Source release map

This archive accompanies Scavland Mod Manager runtime release 0.1.2.

- `ScavlandModManager`: installer, manifest, packaging scripts and notices.
- `ScavlandMelonHost`: BepInEx bridge-plugin source.
- `MelonLoader-ScavlandCompat`: MelonLoader 0.7.3 source with the changes
  described in `ScavlandModManager/BRIDGE_CHANGES.md`.
- `BepInEx-6.0.0-be.788`: BepInEx source at commit
  `5b766a3b7f6c164d4798924a93f3acf4db769d06`, including the Scavland
  quiet-logging patch documented in `ScavlandModManager/BRIDGE_CHANGES.md`,
  used to produce the packaged BepInEx runtime.

No Scavland game file, game assembly, user save, user configuration or
third-party MOD is in this source archive.
'@ | Set-Content -LiteralPath (Join-Path $release 'SOURCE_RELEASE_MAP.md') -Encoding UTF8
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputZip) | Out-Null
    if (Test-Path -LiteralPath $OutputZip) { Remove-Item -LiteralPath $OutputZip -Force }
    Compress-Archive -LiteralPath $release -DestinationPath $OutputZip -CompressionLevel Optimal
    Get-FileHash -LiteralPath $OutputZip -Algorithm SHA256 | Format-List
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
