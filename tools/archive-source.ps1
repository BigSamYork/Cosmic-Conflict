#requires -Version 7.0
param([string]$Version)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
if (-not $Version) { $Version = $config.game_version }
if ($Version -ne $config.game_version -or $Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Archive version must match the current source manifest.' }
$destination = Join-Path $root "releases\$Version\CosmicConflict-$Version-Source.zip"
if (Test-Path -LiteralPath $destination) { throw 'The versioned source archive already exists; preserve it rather than silently overwrite it.' }
$files = @(
    foreach ($folder in @('current_dev', 'tools', 'Docs', 'Cockpit_Overlays', 'Gun_Overlays')) {
        Get-ChildItem -LiteralPath (Join-Path $root $folder) -Recurse -File | Where-Object {
            $_.FullName -notmatch '\\\.godot\\|\\\.git\\' -and $_.Extension -notin @('.tmp', '.bak') -and -not $_.Name.StartsWith('~$')
        }
    }
    Get-Item -LiteralPath (Join-Path $root '.gitignore')
) | Sort-Object FullName
$manifest = [Collections.Generic.List[object]]::new()
$zip = [IO.Compression.ZipFile]::Open($destination, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $relative = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName).Hash
        $entry = $zip.CreateEntry($relative, [IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
        $inputStream = [IO.File]::OpenRead($file.FullName)
        $entryStream = $null
        try {
            $entryStream = $entry.Open()
            $inputStream.CopyTo($entryStream)
        } finally {
            if ($null -ne $entryStream) { $entryStream.Dispose() }
            $inputStream.Dispose()
        }
        $manifest.Add([ordered]@{ path = $relative; bytes = $file.Length; sha256 = $hash })
    }
    $entry = $zip.CreateEntry('source-manifest.json')
    $entry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
    $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
    try {
        $writer.Write(([ordered]@{
            version = $Version
            toolchain = $config
            build = 'tools\build.ps1'
            prerequisite = 'Restore the pinned Godot/tools/templates with tools\bootstrap.ps1 or reuse their existing offline cache. Cached binaries, releases and user saves are intentionally excluded.'
            files = $manifest
        } | ConvertTo-Json -Depth 6))
    } finally { $writer.Dispose() }
} finally { $zip.Dispose() }
$zip = [IO.Compression.ZipFile]::OpenRead($destination)
try {
    foreach ($file in $manifest) {
        $entry = $zip.GetEntry($file.path)
        if ($null -eq $entry -or $entry.Length -ne $file.bytes) { throw "Source archive entry is missing or truncated: $($file.path)" }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $actual = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') } finally { $stream.Dispose(); $sha.Dispose() }
        if ($actual -ne $file.sha256) { throw "Source archive fingerprint mismatch: $($file.path)" }
    }
} finally { $zip.Dispose() }
Get-FileHash -LiteralPath $destination | Format-List
Write-Output "SOURCE_ARCHIVE_VERIFIED files=$($manifest.Count) path=$destination"
