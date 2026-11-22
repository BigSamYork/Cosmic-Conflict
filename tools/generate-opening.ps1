param([string]$OutputDirectory)
& (Join-Path $PSScriptRoot 'generate-voice.ps1') -Opening -Overwrite -OutputDirectory $OutputDirectory
