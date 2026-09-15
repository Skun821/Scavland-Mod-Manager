[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $BepInExRoot,
    [Parameter(Mandatory = $true)] [string] $BridgeDll,
    [Parameter(Mandatory = $true)] [string] $CustomMelonLoaderDll,
    [Parameter(Mandatory = $true)] [string] $BepInExLicense,
    [Parameter(Mandatory = $true)] [string] $MelonLoaderLicense,
    [Parameter(Mandatory = $true)] [string] $MelonLoaderNotice,
    [Parameter(Mandatory = $true)] [string] $OutputZip
)

$ErrorActionPreference = 'Stop'
foreach ($path in @($BepInExRoot, $BridgeDll, $CustomMelonLoaderDll, $BepInExLicense, $MelonLoaderLicense, $MelonLoaderNotice)) {
    if (-not (Test-Path $path)) { throw "Required input was not found: $path" }
}

$stage = Join-Path ([IO.Path]::GetTempPath()) ('ScavlandRuntimePayload-' + [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    $payload = Join-Path $stage 'Scavland-BepInEx-Runtime'
    New-Item -ItemType Directory -Force -Path $payload | Out-Null
    Copy-Item -LiteralPath (Join-Path $BepInExRoot 'BepInEx') -Destination (Join-Path $payload 'BepInEx') -Recurse -Force
    foreach ($directory in @('plugins', 'patchers', 'cache', 'DumpedAssemblies', 'config')) {
        $remove = Join-Path $payload (Join-Path 'BepInEx' $directory)
        if (Test-Path $remove) { Remove-Item -LiteralPath $remove -Recurse -Force }
    }
    Get-ChildItem -LiteralPath (Join-Path $payload 'BepInEx') -File -Filter 'LogOutput*.log' | Remove-Item -Force
    foreach ($name in @('winhttp.dll', 'doorstop_config.ini')) {
        $source = Join-Path $BepInExRoot $name
        if (-not (Test-Path $source)) { throw "BepInEx runtime file was not found: $source" }
        Copy-Item -LiteralPath $source -Destination (Join-Path $payload $name) -Force
    }
    $pluginDirectory = Join-Path $payload 'BepInEx\plugins'
    New-Item -ItemType Directory -Force -Path $pluginDirectory | Out-Null
    Copy-Item -LiteralPath $BridgeDll -Destination (Join-Path $pluginDirectory 'ScavlandMelonHost.dll') -Force
    $melonDirectory = Join-Path $payload 'MelonLoader\net472'
    New-Item -ItemType Directory -Force -Path $melonDirectory | Out-Null
    Copy-Item -LiteralPath $CustomMelonLoaderDll -Destination (Join-Path $melonDirectory 'MelonLoader.dll') -Force
    $licenseDirectory = Join-Path $payload 'LICENSES'
    New-Item -ItemType Directory -Force -Path $licenseDirectory | Out-Null
    Copy-Item -LiteralPath $BepInExLicense -Destination (Join-Path $licenseDirectory 'BepInEx-LGPL-2.1.txt') -Force
    Copy-Item -LiteralPath $MelonLoaderLicense -Destination (Join-Path $licenseDirectory 'MelonLoader-Apache-2.0.txt') -Force
    Copy-Item -LiteralPath $MelonLoaderNotice -Destination (Join-Path $licenseDirectory 'MelonLoader-NOTICE.txt') -Force
    @'
Payload composition:
- BepInEx 6.0.0-be.788 (commit 5b766a3b7f6c164d4798924a93f3acf4db769d06),
  with the Scavland quiet-logging patch only. It suppresses two known non-fatal
  Unity-log-forwarding messages caused by stripped Unity APIs; normal BepInEx
  file/console logging and MOD error logging remain enabled.
- ScavlandMelonHost.dll, this project's BepInEx bridge plugin.
- Modified MelonLoader.dll based on MelonLoader 0.7.3 (commit 982ed99).

The matching source release contains the host source, the modified MelonLoader
source, the payload build script, notices, and build instructions. This archive
contains no Scavland game assembly, user configuration, or third-party MOD.
'@ | Set-Content -LiteralPath (Join-Path $licenseDirectory 'PAYLOAD-NOTICE.txt') -Encoding UTF8
    if (Test-Path $OutputZip) { Remove-Item -LiteralPath $OutputZip -Force }
    New-Item -ItemType Directory -Force -Path (Split-Path $OutputZip) | Out-Null
    Compress-Archive -LiteralPath $payload -DestinationPath $OutputZip -CompressionLevel Optimal
    Get-FileHash -LiteralPath $OutputZip -Algorithm SHA256 | Format-List
}
finally {
    if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
