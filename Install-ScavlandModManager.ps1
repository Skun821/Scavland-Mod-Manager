[CmdletBinding()]
param(
    [ValidateSet('Install', 'Status', 'Restore', 'Launch', 'Diagnose')]
    [string] $Action = 'Install',
    [string] $GamePath,
    [string] $ManifestPath,
    [string] $RuntimeArchive,
    [string] $MelonLoaderArchive
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ManifestPath)) { $ManifestPath = Join-Path $PSScriptRoot 'manager.manifest.json' }
$CompatibilityFiles = @(
    'mscorlib.dll',
    'System.dll',
    'System.Core.dll',
    'System.Configuration.dll',
    'System.Data.dll',
    'System.Drawing.dll',
    'System.Net.Http.dll',
    'System.Numerics.dll',
    'System.Runtime.Serialization.dll',
    'System.Xml.dll',
    'System.Xml.Linq.dll'
)

function Get-DefaultGamePath {
    $steamPath = 'C:\Program Files (x86)\Steam\steamapps\common\Scavland'
    if (Test-Path (Join-Path $steamPath 'Scavland.exe')) { return $steamPath }
    throw 'Scavland.exe was not found. Start again with -GamePath <Scavland folder>.'
}

function Assert-Hash([string] $Path, [string] $Expected, [string] $Label) {
    if ($Expected -notmatch '^[A-Fa-f0-9]{64}$') {
        throw "$Label has no valid pinned SHA-256 in manager.manifest.json. Refusing an unverified download."
    }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -ne $Expected.ToUpperInvariant()) {
        throw "$Label SHA-256 mismatch. Expected $Expected but downloaded $actual."
    }
}

function Get-VerifiedArchive([object] $Entry, [string] $Label, [string] $WorkDirectory, [string] $LocalArchive) {
    $archive = Join-Path $WorkDirectory ("$Label.zip")
    if (-not [string]::IsNullOrWhiteSpace($LocalArchive)) {
        if (-not (Test-Path -LiteralPath $LocalArchive)) { throw "$Label local archive was not found: $LocalArchive" }
        Write-Host "Verifying local $Label archive..."
        Copy-Item -LiteralPath $LocalArchive -Destination $archive -Force
    }
    else {
        if ([string]$Entry.url -match 'REPLACE_OWNER') {
            throw "$Label release URL is not configured. Use a published manager manifest, or provide the verified local archive explicitly."
        }
        $uri = [Uri]$Entry.url
        if ($uri.Scheme -ne 'https') { throw "$Label URL must use HTTPS." }
        Write-Host "Downloading $Label $($Entry.version)..."
        Invoke-WebRequest -Uri $Entry.url -OutFile $archive -UseBasicParsing
    }
    Assert-Hash $archive ([string]$Entry.sha256) $Label
    $destination = Join-Path $WorkDirectory $Label
    Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
    return $destination
}

function Copy-Directory([string] $Source, [string] $Destination) {
    if (-not (Test-Path $Source)) { throw "Required payload path is missing: $Source" }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Get-CompatibilitySource([string] $MelonExtract) {
    $candidate = Get-ChildItem -LiteralPath $MelonExtract -Recurse -Directory |
        Where-Object { $_.Name -eq 'MonoBleedingEdgePatches' } |
        Select-Object -First 1
    if ($null -eq $candidate) { throw 'The official MelonLoader archive does not contain MonoBleedingEdgePatches.' }
    foreach ($name in $CompatibilityFiles) {
        if (-not (Test-Path (Join-Path $candidate.FullName $name))) { throw "MelonLoader is missing compatibility file: $name" }
    }
    return $candidate.FullName
}

function Get-StatePath([string] $Root) { Join-Path $Root 'ScavlandModManager\state.json' }
function Get-BackupPath([string] $Root) { Join-Path $Root 'ScavlandModManager\backup\Managed-original' }

function Save-State([string] $Root, [object] $State) {
    $path = Get-StatePath $Root
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    $State | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
}

function Backup-Managed([string] $Root, [string] $Managed, [string] $Compatibility) {
    $backup = Get-BackupPath $Root
    if (Test-Path $backup) { return $backup }
    $alreadyPatched = 0
    foreach ($name in $CompatibilityFiles) {
        $gameFile = Join-Path $Managed $name
        $patchFile = Join-Path $Compatibility $name
        if (-not (Test-Path $gameFile)) { throw "Game compatibility file is missing: $gameFile" }
        if ((Get-FileHash -LiteralPath $gameFile -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $patchFile -Algorithm SHA256).Hash) {
            $alreadyPatched++
        }
    }
    if ($alreadyPatched -gt 0) {
        throw 'Managed already contains some MelonLoader compatibility DLLs, but this manager has no verified original backup. Refusing to create a bad backup. Restore the game DLLs first, or keep using the existing loader installation.'
    }
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    foreach ($name in $CompatibilityFiles) {
        Copy-Item -LiteralPath (Join-Path $Managed $name) -Destination (Join-Path $backup $name) -Force
    }
    return $backup
}

function Install-Runtime([string] $Root, [object] $Manifest, [string] $LocalRuntimeArchive, [string] $LocalMelonLoaderArchive) {
    if (Get-Process -Name 'Scavland' -ErrorAction SilentlyContinue) { throw 'Scavland is running. Close it before installing.' }
    $managed = Join-Path $Root 'Scavland_Data\Managed'
    if (-not (Test-Path $managed)) { throw "Managed directory was not found: $managed" }
    $work = Join-Path ([IO.Path]::GetTempPath()) ('ScavlandModManager-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $backup = $null
    $managedChanged = $false
    try {
        $runtime = Get-VerifiedArchive $Manifest.runtime 'ScavlandRuntime' $work $LocalRuntimeArchive
        $melon = Get-VerifiedArchive $Manifest.melonLoader 'MelonLoader' $work $LocalMelonLoaderArchive
        $payload = Get-ChildItem -LiteralPath $runtime -Recurse -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName 'BepInEx') } |
            Select-Object -First 1
        if ($null -eq $payload) { throw 'Runtime archive does not contain a BepInEx payload root.' }

        $compatibility = Get-CompatibilitySource $melon
        $backup = Backup-Managed $Root $managed $compatibility
        $managedChanged = $true
        foreach ($name in $CompatibilityFiles) {
            Copy-Item -LiteralPath (Join-Path $compatibility $name) -Destination (Join-Path $managed $name) -Force
        }

        Copy-Directory (Join-Path $payload.FullName 'BepInEx') (Join-Path $Root 'BepInEx')
        foreach ($name in @('winhttp.dll', 'doorstop_config.ini')) {
            $source = Join-Path $payload.FullName $name
            if (Test-Path $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $Root $name) -Force }
        }

        $melonRoot = Get-ChildItem -LiteralPath $melon -Recurse -Directory |
            Where-Object { $_.Name -eq 'MelonLoader' -and (Test-Path (Join-Path $_.FullName 'net472')) } |
            Select-Object -First 1
        if ($null -eq $melonRoot) { throw 'Official MelonLoader runtime directory was not found.' }
        Copy-Directory $melonRoot.FullName (Join-Path $Root 'MelonLoader')
        $customMelon = Join-Path $payload.FullName 'MelonLoader'
        if (Test-Path $customMelon) {
            Copy-Directory $customMelon (Join-Path $Root 'MelonLoader')
        }
        New-Item -ItemType Directory -Force -Path (Join-Path $Root 'Mods'), (Join-Path $Root 'Plugins'), (Join-Path $Root 'UserLibs'), (Join-Path $Root 'UserData') | Out-Null

        Save-State $Root ([pscustomobject]@{
            schema = 1
            installedAtUtc = [DateTime]::UtcNow.ToString('o')
            runtimeVersion = $Manifest.runtime.version
            melonLoaderVersion = $Manifest.melonLoader.version
            backupPath = $backup
        })
        Write-Host 'Install complete. Use ScavlandModManager.cmd -Action Launch to start the game through this manager.' -ForegroundColor Green
    }
    catch {
        if ($managedChanged -and $null -ne $backup -and (Test-Path $backup)) {
            foreach ($name in $CompatibilityFiles) {
                Copy-Item -LiteralPath (Join-Path $backup $name) -Destination (Join-Path $managed $name) -Force
            }
            Write-Warning 'Install failed. The original Managed compatibility DLLs were restored.'
        }
        throw
    }
    finally {
        if (Test-Path $work) {
            try { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction Stop }
            catch { Write-Warning "Temporary download cleanup was deferred: $work" }
        }
    }
}

function Restore-Managed([string] $Root) {
    if (Get-Process -Name 'Scavland' -ErrorAction SilentlyContinue) { throw 'Scavland is running. Close it before restoring.' }
    $managed = Join-Path $Root 'Scavland_Data\Managed'
    $backup = Get-BackupPath $Root
    if (-not (Test-Path $backup)) { throw 'No managed-DLL backup was found.' }
    foreach ($name in $CompatibilityFiles) {
        Copy-Item -LiteralPath (Join-Path $backup $name) -Destination (Join-Path $managed $name) -Force
    }
    Write-Host 'The original Managed compatibility files were restored. BepInEx and user MOD files were left untouched.' -ForegroundColor Green
}

function Invoke-Diagnose([string] $Root) {
    $logCandidates = @(
        (Join-Path $Root 'BepInEx\LogOutput.log'),
        (Join-Path $Root 'MelonLoader\Latest.log'),
        (Join-Path $Root 'MelonLoader\MelonLoader.log')
    ) | Where-Object { Test-Path -LiteralPath $_ }
    if ($logCandidates.Count -eq 0) {
        Write-Host 'No BepInEx or MelonLoader log was found yet. Start the game once, then run Diagnose again.' -ForegroundColor Yellow
        return
    }

    $rules = @(
        @{ Pattern = 'CustomAttributeFormatException|Could not find a field with name CharSet'; Message = 'The game Managed DLL compatibility patch is missing or was overwritten by a Steam update. Restore/install through this manager after closing the game.' },
        @{ Pattern = 'AssemblyName\.get_ProcessorArchitecture|UnverifiableCodeAttribute|DynamicILInfo'; Message = 'A Melon MOD reached Harmony/MonoMod code that Scavland runtime does not currently provide. This needs a bridge compatibility update; it is not a MOD installation error.' },
        @{ Pattern = 'Scavland MelonLoader Host.*failed to start|compatibility entry points were not found'; Message = 'The bridge runtime and host DLL versions do not match. Reinstall the same published manager release.' },
        @{ Pattern = 'SkipInit'; Message = 'System.Runtime.CompilerServices.Unsafe.dll may have been overwritten. Keep Scavland own Unsafe DLL and restore it through Steam or a known-good backup.' }
    )

    $lines = foreach ($log in $logCandidates) { Select-String -LiteralPath $log -Pattern '.' | ForEach-Object { [pscustomobject]@{ Log = $log; Line = $_.Line } } }
    $reported = 0
    foreach ($rule in $rules) {
        $matches = $lines | Where-Object { $_.Line -match $rule.Pattern }
        if (@($matches).Count -gt 0) {
            $reported++
            Write-Host "[$reported] $($rule.Message)" -ForegroundColor Yellow
            $matches | Select-Object -Last 2 | ForEach-Object { Write-Host "    $($_.Log): $($_.Line)" }
        }
    }
    if ($reported -eq 0) { Write-Host 'No known bridge compatibility signature was found in the available logs.' -ForegroundColor Green }
}

if (-not (Test-Path $ManifestPath)) { throw "Manifest was not found: $ManifestPath" }
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($GamePath)) { $GamePath = Get-DefaultGamePath }
$root = (Resolve-Path -LiteralPath $GamePath).Path
$exe = Join-Path $root $manifest.gameExecutable
if (-not (Test-Path $exe)) { throw "Expected game executable was not found: $exe" }

switch ($Action) {
    'Install' { Install-Runtime $root $manifest $RuntimeArchive $MelonLoaderArchive }
    'Restore' { Restore-Managed $root }
    'Status' {
        $state = Get-StatePath $root
        [pscustomobject]@{
            GamePath = $root
            Installed = Test-Path $state
            BepInEx = Test-Path (Join-Path $root 'BepInEx\plugins\ScavlandMelonHost.dll')
            MelonRuntime = Test-Path (Join-Path $root 'MelonLoader\net472\MelonLoader.dll')
            ManagedBackup = Test-Path (Get-BackupPath $root)
        } | Format-List
    }
    'Launch' {
        if (-not (Test-Path (Get-StatePath $root))) { throw 'Runtime is not installed. Run with -Action Install first.' }
        Start-Process -FilePath $exe -WorkingDirectory $root
    }
    'Diagnose' { Invoke-Diagnose $root }
}
