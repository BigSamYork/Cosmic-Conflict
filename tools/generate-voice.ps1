param(
    [string]$OutputDirectory,
    [switch]$Overwrite
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$voiceDirectory = Join-Path $root 'current_dev\assets\voice'
if (-not $OutputDirectory) { $OutputDirectory = $voiceDirectory }
& (Join-Path $voiceDirectory 'generate-voice.ps1') -CatalogPath (Join-Path $voiceDirectory 'lines.json') -OutputDirectory $OutputDirectory -Overwrite:$Overwrite
