[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $GameDirectory
)

$ErrorActionPreference = 'Stop'

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string] $Source,
        [Parameter(Mandatory = $true)][string] $Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

$packageDirectory = Split-Path -Parent $PSCommandPath
$runtimeDirectory = Join-Path $packageDirectory 'Runtime'
$gameDirectory = [System.IO.Path]::GetFullPath($GameDirectory.Trim().Trim('"'))
$gameExe = Join-Path $gameDirectory 'Scavland.exe'

if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
    throw "Scavland.exe was not found in: $gameDirectory"
}
if (-not (Test-Path -LiteralPath (Join-Path $runtimeDirectory 'BepInEx\core') -PathType Container)) {
    throw 'The bundled official BepInEx core is missing. Re-extract the ZIP and try again.'
}

$bepInExDirectory = Join-Path $gameDirectory 'BepInEx'
$coreDirectory = Join-Path $bepInExDirectory 'core'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host 'Scavland Mod Runtime 0.2.1' -ForegroundColor Cyan
Write-Host "Target: $gameDirectory"
Write-Host 'This installer does not modify Scavland_Data or any game DLL.' -ForegroundColor Green

if (Test-Path -LiteralPath $coreDirectory -PathType Container) {
    $backupDirectory = Join-Path $bepInExDirectory ("core.before-ScavlandModRuntime-0.2.1-$timestamp")
    Write-Host "Backing up existing BepInEx core to: $([System.IO.Path]::GetFileName($backupDirectory))"
    Move-Item -LiteralPath $coreDirectory -Destination $backupDirectory
}

Copy-DirectoryContents -Source (Join-Path $runtimeDirectory 'BepInEx\core') -Destination $coreDirectory

$targetConfigDirectory = Join-Path $bepInExDirectory 'config'
$targetConfig = Join-Path $targetConfigDirectory 'BepInEx.cfg'
if (-not (Test-Path -LiteralPath $targetConfig -PathType Leaf)) {
    New-Item -ItemType Directory -Force -Path $targetConfigDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $runtimeDirectory 'BepInEx\config\BepInEx.cfg') -Destination $targetConfig
    Write-Host 'Installed the default BepInEx configuration.'
} else {
    Write-Host 'Kept the existing BepInEx configuration.'
}

$targetPluginDirectory = Join-Path $bepInExDirectory 'plugins'
New-Item -ItemType Directory -Force -Path $targetPluginDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $runtimeDirectory 'BepInEx\plugins\ScavlandMelonHost.dll') -Destination (Join-Path $targetPluginDirectory 'ScavlandMelonHost.dll') -Force

foreach ($folder in @('Mods', 'Plugins', 'UserLibs')) {
    $source = Join-Path $runtimeDirectory $folder
    $destination = Join-Path $gameDirectory $folder
    Copy-DirectoryContents -Source $source -Destination $destination
}

Copy-Item -LiteralPath (Join-Path $runtimeDirectory 'winhttp.dll') -Destination (Join-Path $gameDirectory 'winhttp.dll') -Force
Copy-Item -LiteralPath (Join-Path $runtimeDirectory 'doorstop_config.ini') -Destination (Join-Path $gameDirectory 'doorstop_config.ini') -Force

Write-Host ''
Write-Host 'Installed:' -ForegroundColor Green
Write-Host '  - Official unmodified BepInEx 6.0.0-be.788 core'
Write-Host '  - Scavland Melon compatibility host'
Write-Host '  - Empty Mods / Plugins / UserLibs folders for compatible Melon mods'
Write-Host ''
Write-Host 'Your existing BepInEx plugins, settings, and save data were kept.'
