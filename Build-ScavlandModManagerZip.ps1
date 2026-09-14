[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $OutputZip
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$files = @(
    'ScavlandModManager.cmd',
    'Install-ScavlandModManager.ps1',
    'manager.manifest.json',
    'README.md',
    'LICENSE',
    'THIRD_PARTY_NOTICES.md',
    'BRIDGE_CHANGES.md',
    'COMPATIBILITY.md',
    'BUILD.md',
    'RELEASE_CHECKLIST.md',
    'RELEASE_NOTES_v0.1.0.md'
)
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $file))) { throw "Required bootstrap file is missing: $file" }
}

$stage = Join-Path ([IO.Path]::GetTempPath()) ('ScavlandModManagerZip-' + [Guid]::NewGuid().ToString('N'))
try {
    $package = Join-Path $stage 'ScavlandModManager'
    New-Item -ItemType Directory -Path $package -Force | Out-Null
    foreach ($file in $files) {
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $package $file) -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputZip) | Out-Null
    if (Test-Path -LiteralPath $OutputZip) { Remove-Item -LiteralPath $OutputZip -Force }
    Compress-Archive -LiteralPath $package -DestinationPath $OutputZip -CompressionLevel Optimal
    Get-FileHash -LiteralPath $OutputZip -Algorithm SHA256 | Format-List
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
