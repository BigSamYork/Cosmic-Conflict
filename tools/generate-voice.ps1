param(
    [string]$OutputDirectory,
    [switch]$Opening,
    [switch]$Arrival,
    [switch]$Boarding,
    [switch]$Bosses,
    [switch]$Overwrite
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$voiceDirectory = Join-Path $root 'current_dev\assets\voice'
$catalog = if ($Bosses) { 'bosses.json' } elseif ($Boarding) { 'boarding.json' } elseif ($Arrival) { 'arrival.json' } elseif ($Opening) { 'opening.json' } else { 'lines.json' }
if (-not $OutputDirectory) {
    $OutputDirectory = if ($Bosses) { Join-Path $voiceDirectory 'bosses' } elseif ($Boarding) { Join-Path $root 'current_dev\assets\boarding' } elseif ($Arrival) { Join-Path $root 'current_dev\assets\arrival' } elseif ($Opening) { Join-Path $root 'current_dev\assets\opening' } else { $voiceDirectory }
}
$python = $env:COSMIC_TTS_PYTHON
if (-not $python) { $python = Join-Path $root '.tools\chatterbox\Scripts\python.exe' }
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    throw 'Install the Chatterbox authoring environment or set COSMIC_TTS_PYTHON. See Docs/FLIGHT_LAB.md.'
}
$arguments = @((Join-Path $voiceDirectory 'render_chatterbox.py'), (Join-Path $voiceDirectory $catalog), $OutputDirectory)
$localModel = Join-Path $root '.tools\turbo-model'
if (-not $env:COSMIC_TTS_MODEL -and (Test-Path -LiteralPath (Join-Path $localModel 't3_turbo_v1.safetensors'))) {
    $arguments += @('--model', $localModel)
}
if ($Overwrite) { $arguments += '--overwrite' }
& $python @arguments
if ($LASTEXITCODE -ne 0) { throw "Chatterbox generation failed (exit $LASTEXITCODE)." }
