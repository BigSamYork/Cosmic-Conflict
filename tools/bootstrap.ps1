param([switch]$SkipTemplates, [ValidateSet('Windows','Android','All')][string]$Platform = 'Windows')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Content (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$version = $config.godot
$cache = Join-Path $root '.tools\downloads'
$engine = Join-Path $root '.tools\godot'
$templates = Join-Path $root '.tools\templates'
New-Item -ItemType Directory -Force -Path $cache, $engine, $templates | Out-Null
$baseUrl = "https://github.com/godotengine/godot-builds/releases/download/$version"

function Get-Download([string]$Name) {
    $destination = Join-Path $cache $Name
    if (-not (Test-Path -LiteralPath $destination)) {
        & curl.exe --fail --location --silent --show-error --retry 2 --connect-timeout 20 --max-time 1200 --output "$destination.tmp" "$baseUrl/$Name"
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $Name (curl exit $LASTEXITCODE). Retry bootstrap when connected." }
        Move-Item -LiteralPath "$destination.tmp" -Destination $destination
    }
    return $destination
}

$sums = Get-Download 'SHA512-SUMS.txt'
function Get-VerifiedArchive([string]$Name) {
    $archive = Get-Download $Name
    $line = Get-Content -LiteralPath $sums | Where-Object { $_ -match "\s+\*?$([regex]::Escape($Name))$" } | Select-Object -First 1
    if (-not $line) { throw "Official SHA-512 checksum missing for $Name." }
    $expected = ($line -split '\s+')[0]
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash -ne $expected) {
        throw "Checksum mismatch for $archive. Do not use this download."
    }
    return $archive
}

$editor = Get-VerifiedArchive "Godot_v$($version)_win64.exe.zip"
Expand-Archive -LiteralPath $editor -DestinationPath $engine -Force
if (-not $SkipTemplates) {
    . (Join-Path $PSScriptRoot 'windows-templates.ps1')
    $names = @()
    if ($Platform -ne 'Android') { $names += 'windows_debug_x86_64.exe', 'windows_release_x86_64.exe' }
    if ($Platform -ne 'Windows') { $names += 'android_release.apk' }
    Install-ExportTemplates -Url "$baseUrl/Godot_v$($version)_export_templates.tpz" -Destination $templates -Names $names
}
$executable = Join-Path $engine "Godot_v$($version)_win64_console.exe"
& $executable --version
if ($LASTEXITCODE -ne 0) { throw 'Godot startup failed.' }
Write-Host "Verified portable engine available at $engine"
