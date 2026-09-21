[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $GameDirectory
)

$ErrorActionPreference = 'Stop'

$bepInExVersion = '6.0.0-be.788+5b766a3'
$bepInExUri = 'https://builds.bepinex.dev/projects/bepinex_be/788/BepInEx-Unity.Mono-win-x64-6.0.0-be.788%2B5b766a3.zip'
$bepInExSha256 = 'D7455185E8A0A01EB122947C59229F3FFCCEED853FEBD4707C08219743D8F477'
$melonLoaderVersion = '0.7.3'
$melonLoaderUri = 'https://github.com/LavaGang/MelonLoader/releases/download/v0.7.3/MelonLoader.x64.zip'
$melonLoaderSha256 = '5B2B2F3D1CD42B59EC886C5BDC2663EDAE87A0097A4F4A8F58C0965A99DDA416'

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

function Download-AndVerify {
    param([string] $Uri, [string] $Destination, [string] $ExpectedSha256, [string] $Label)
    Write-Host "Downloading official $Label..."
    Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing
    $actual = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($actual -ne $ExpectedSha256) { throw "$Label SHA-256 mismatch. Expected $ExpectedSha256 but received $actual." }
    Write-Host "Verified ${Label}: $actual" -ForegroundColor Green
}

$packageDirectory = Split-Path -Parent $PSCommandPath
$runtimeDirectory = Join-Path $packageDirectory 'Runtime'
$gameDirectory = [System.IO.Path]::GetFullPath($GameDirectory.Trim().Trim('"'))
$gameExe = Join-Path $gameDirectory 'Scavland.exe'
$customHost = Join-Path $runtimeDirectory 'BepInEx\plugins\ScavlandMelonHost.dll'
$customMelonLoader = Join-Path $runtimeDirectory 'ScavlandMelonLoader.dll'

if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
    throw "Scavland.exe was not found in: $gameDirectory"
}
if (-not (Test-Path -LiteralPath $customHost -PathType Leaf)) { throw 'ScavlandMelonHost.dll is missing from the package.' }
if (-not (Test-Path -LiteralPath $customMelonLoader -PathType Leaf)) { throw 'ScavlandMelonLoader.dll is missing from the package.' }
if (Get-Process -Name 'Scavland' -ErrorAction SilentlyContinue) { throw 'Scavland is running. Close it before installing.' }

$bepInExDirectory = Join-Path $gameDirectory 'BepInEx'
$coreDirectory = Join-Path $bepInExDirectory 'core'
$melonLoaderDirectory = Join-Path $gameDirectory 'MelonLoader'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$workDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('ScavlandModRuntime-' + [Guid]::NewGuid().ToString('N'))

Write-Host 'Scavland Mod Runtime 0.2.0' -ForegroundColor Cyan
Write-Host "Target: $gameDirectory"
Write-Host 'Official downloads are verified before the Scavland compatibility layer is applied.' -ForegroundColor Green

New-Item -ItemType Directory -Force -Path $workDirectory | Out-Null
try {
    $bepInExArchive = Join-Path $workDirectory 'BepInEx.zip'
    $melonLoaderArchive = Join-Path $workDirectory 'MelonLoader.zip'
    Download-AndVerify $bepInExUri $bepInExArchive $bepInExSha256 "BepInEx $bepInExVersion"
    Download-AndVerify $melonLoaderUri $melonLoaderArchive $melonLoaderSha256 "MelonLoader $melonLoaderVersion"
    $bepInExExtract = Join-Path $workDirectory 'BepInExExtract'
    $melonLoaderExtract = Join-Path $workDirectory 'MelonLoaderExtract'
    Expand-Archive -LiteralPath $bepInExArchive -DestinationPath $bepInExExtract -Force
    Expand-Archive -LiteralPath $melonLoaderArchive -DestinationPath $melonLoaderExtract -Force
    $officialBepInEx = Join-Path $bepInExExtract 'BepInEx'
    $officialMelonLoader = Join-Path $melonLoaderExtract 'MelonLoader'
    if (-not (Test-Path -LiteralPath (Join-Path $officialBepInEx 'core') -PathType Container)) { throw 'The official BepInEx archive has an unexpected layout.' }
    if (-not (Test-Path -LiteralPath (Join-Path $officialMelonLoader 'net472\MelonLoader.dll') -PathType Leaf)) { throw 'The official MelonLoader archive has an unexpected layout.' }

if (Test-Path -LiteralPath $coreDirectory -PathType Container) {
    $backupDirectory = Join-Path $bepInExDirectory ("core.before-ScavlandModRuntime-0.2.0-$timestamp")
    Write-Host "Backing up existing BepInEx core to: $([System.IO.Path]::GetFileName($backupDirectory))"
    Move-Item -LiteralPath $coreDirectory -Destination $backupDirectory
}

Copy-DirectoryContents -Source (Join-Path $officialBepInEx 'core') -Destination $coreDirectory

$targetConfigDirectory = Join-Path $bepInExDirectory 'config'
$targetConfig = Join-Path $targetConfigDirectory 'BepInEx.cfg'
if (-not (Test-Path -LiteralPath $targetConfig -PathType Leaf)) {
    New-Item -ItemType Directory -Force -Path $targetConfigDirectory | Out-Null
    $defaultConfig = Join-Path $officialBepInEx 'config\BepInEx.cfg'
    if (-not (Test-Path -LiteralPath $defaultConfig -PathType Leaf)) {
        $defaultConfig = Join-Path $runtimeDirectory 'BepInEx\config\BepInEx.cfg'
    }
    Copy-Item -LiteralPath $defaultConfig -Destination $targetConfig
    Write-Host 'Installed the default BepInEx configuration.'
} else {
    Write-Host 'Kept the existing BepInEx configuration.'
}

$configText = Get-Content -LiteralPath $targetConfig -Raw
$configText = [regex]::Replace($configText, '(?m)(^\[Logging\.Console\]\r?\nEnabled\s*=\s*)false\s*$', '${1}true')
Set-Content -LiteralPath $targetConfig -Value $configText -Encoding UTF8
Write-Host 'Enabled the BepInEx console log window.'

$targetPluginDirectory = Join-Path $bepInExDirectory 'plugins'
New-Item -ItemType Directory -Force -Path $targetPluginDirectory | Out-Null
Copy-Item -LiteralPath $customHost -Destination (Join-Path $targetPluginDirectory 'ScavlandMelonHost.dll') -Force

if (Test-Path -LiteralPath $melonLoaderDirectory -PathType Container) {
    Move-Item -LiteralPath $melonLoaderDirectory -Destination (Join-Path $gameDirectory "MelonLoader.before-ScavlandModRuntime-0.2.0-$timestamp")
}
Copy-DirectoryContents -Source $officialMelonLoader -Destination $melonLoaderDirectory
Copy-Item -LiteralPath $customMelonLoader -Destination (Join-Path $melonLoaderDirectory 'net472\MelonLoader.dll') -Force

foreach ($folder in @('Mods', 'Plugins', 'UserLibs')) {
    $source = Join-Path $runtimeDirectory $folder
    $destination = Join-Path $gameDirectory $folder
    Copy-DirectoryContents -Source $source -Destination $destination
}

Copy-Item -LiteralPath (Join-Path $bepInExExtract 'winhttp.dll') -Destination (Join-Path $gameDirectory 'winhttp.dll') -Force
Copy-Item -LiteralPath (Join-Path $bepInExExtract 'doorstop_config.ini') -Destination (Join-Path $gameDirectory 'doorstop_config.ini') -Force

Write-Host ''
Write-Host 'Installed:' -ForegroundColor Green
Write-Host "  - Official BepInEx $bepInExVersion"
Write-Host "  - Official MelonLoader $melonLoaderVersion runtime files"
Write-Host '  - Scavland compatibility MelonLoader.dll and BepInEx host'
Write-Host '  - Empty Mods / Plugins / UserLibs folders for compatible Melon mods'
Write-Host ''
Write-Host 'The native MelonLoader bootstrap (version.dll / dobby.dll) was not installed because BepInEx owns the Unity bootstrap.'
Write-Host 'Existing BepInEx plugins, settings, and save data were kept.'
}
finally {
    if (Test-Path -LiteralPath $workDirectory) { Remove-Item -LiteralPath $workDirectory -Recurse -Force -ErrorAction SilentlyContinue }
}
