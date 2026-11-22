param(
    [string]$Godot,
    [string]$Iscc,
    [switch]$TestOnly,
    # Release version to stamp into the game, executable and installer; defaults to toolchain.json game_version.
    [string]$Version
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Content (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
if (-not $Version) { $Version = $config.game_version }
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must be MAJOR.MINOR.PATCH, not '$Version'." }
if (-not $Godot) { $Godot = Join-Path $root ".tools\godot\Godot_v$($config.godot)_win64_console.exe" }
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Godot is missing. Run tools\bootstrap.ps1 or supply -Godot.' }
$project = Join-Path $root 'current_dev'
function Assert-VoiceRecordings([string]$Folder, [string]$Index, [array]$Lines, [string]$Voice) {
    $proof = Get-Content -LiteralPath (Join-Path $Folder $Index) -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($proof.model -cne 'ResembleAI/chatterbox-turbo' -or $proof.voice -cne $Voice -or $proof.clips.Count -ne $Lines.Count) {
        throw "Chatterbox-Turbo recordings need regeneration: $Index"
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        foreach ($line in $Lines) {
            $clip = @($proof.clips | Where-Object { $_.id -ceq $line.id })
            $textHash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($line.text))).Replace('-', '')
            $speaker = if ($line.PSObject.Properties['speaker']) { $line.speaker } else { 'lark' }
            $path = Join-Path $Folder ($line.id + '.wav')
            if ($clip.Count -ne 1 -or $clip[0].speaker -cne $speaker -or $clip[0].text_sha256 -ne $textHash -or
                (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $clip[0].audio_sha256) {
                throw "Voice recording needs regeneration: $path"
            }
        }
    } finally { $sha.Dispose() }
}
$voiceFolder = Join-Path $project 'assets/voice'
$voiceCatalog = Get-Content -LiteralPath (Join-Path $voiceFolder 'lines.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-VoiceRecordings $voiceFolder 'generated-voice.json' @($voiceCatalog.sections.lines) $voiceCatalog.voice
$opening = Get-Content -LiteralPath (Join-Path $voiceFolder 'opening.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-VoiceRecordings (Join-Path $project 'assets/opening') 'generated-opening.json' $opening.cues 'opening cast'
$arrival = Get-Content -LiteralPath (Join-Path $voiceFolder 'arrival.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-VoiceRecordings (Join-Path $project 'assets/arrival') 'generated-arrival.json' $arrival.cues 'opening cast'
$release = Join-Path $root "releases\$Version"
$app = Join-Path $release 'app'
New-Item -ItemType Directory -Force -Path $app | Out-Null
function Invoke-Godot([string[]]$Arguments, [switch]$RequireTestCompletion) {
    $output = & $Godot @Arguments 2>&1
    $exit = $LASTEXITCODE
    $output | Write-Host
    if ($exit -ne 0 -or ($output -match 'SCRIPT ERROR:|^ERROR:')) { throw "Godot validation/build failed (exit $exit)." }
    if ($RequireTestCompletion -and -not ($output -match '^[A-Z_]+FAILURES=0$')) { throw 'Test script exited without its successful completion marker.' }
}
# Stamp the version into the project for this build only; the originals are restored afterwards.
$stamped = @{}
try {
    foreach ($stamp in @(
        @{ Path = (Join-Path $project 'project.godot'); Pattern = '(?m)^(config/version=)"[^"\r\n]*"'; Value = "`"$Version`"" },
        @{ Path = (Join-Path $project 'export_presets.cfg'); Pattern = '(?m)^(application/(?:file|product)_version=)"[^"\r\n]*"'; Value = "`"$Version.0`"" }
    )) {
        $text = [IO.File]::ReadAllText($stamp.Path)
        if (-not [regex]::IsMatch($text, $stamp.Pattern)) { throw "Version setting not found in $($stamp.Path)." }
        $updated = [regex]::Replace($text, $stamp.Pattern, "`${1}$($stamp.Value)")
        if ($updated -ne $text) {
            $stamped[$stamp.Path] = [IO.File]::ReadAllBytes($stamp.Path)
            [IO.File]::WriteAllText($stamp.Path, $updated)
        }
    }
    Invoke-Godot @('--headless', '--path', $project, '--editor', '--import', '--quit')
    foreach ($test in @('test_opening.gd', 'test_expansion.gd', 'test_flight.gd', 'test_combat.gd', 'test_campaign.gd', 'test_campaign_completion.gd', 'test_release_polish.gd', 'test_cockpit_layout.gd', 'test_gun_art.gd', 'test_continuous_flight.gd', 'test_orbital_arrival.gd', 'test_asteroid_mining.gd', 'test_encounter_objectives.gd', 'test_thermal_hazards.gd', 'test_radar_rocks_hangar.gd', 'test_secondary_systems.gd', 'test_launch.gd', 'test_countermeasures.gd', 'test_ground_routes.gd', 'test_primary_systems.gd', 'test_sectors.gd', 'test_vespera.gd', 'test_computer_voice.gd', 'test_voice_editor.gd', 'test_xylo.gd', 'test_surface_patrol.gd', 'test_pilot_avionics.gd', 'test_siege_tactics.gd')) {
        Invoke-Godot @('--headless', '--path', $project, '--script', "res://tests/$test", '--quit-after', '600') -RequireTestCompletion
    }
    Invoke-Godot @('--headless', '--path', $project, '--script', 'res://tests/test_voice_editor.gd', '--', '--editor-exit-test') -RequireTestCompletion
    if ($TestOnly) { return }
    Invoke-Godot @('--headless', '--path', $project, '--export-release', 'Windows Desktop', (Join-Path $app 'CosmicConflict.exe'))
    Copy-Item -LiteralPath (Join-Path $root 'Docs\FLIGHT_LAB.md') -Destination $app
    Copy-Item -LiteralPath (Join-Path $root "Docs\Cosmic_Conflict_Player_Manual_v$($config.game_version).docx") -Destination $app
    Copy-Item -LiteralPath (Join-Path $root 'Docs\LICENSES.txt') -Destination $app
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'launch-voice-editor.cmd') -Destination (Join-Path $app 'VoiceEditor.cmd')
    if (-not $Iscc) {
        $candidates = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe")
        $Iscc = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    }
    if (-not $Iscc) { throw 'Inno Setup 6 compiler missing. Supply its path using -Iscc.' }
    & $Iscc "/DRoot=$root" "/DGameVersion=$Version" "/DManualVersion=$($config.game_version)" (Join-Path $PSScriptRoot 'installer.iss')
    if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
    Get-FileHash -LiteralPath (Join-Path $release "CosmicConflict-$Version-Setup.exe") -Algorithm SHA256 | Format-List
} finally {
    foreach ($path in $stamped.Keys) { [IO.File]::WriteAllBytes($path, $stamped[$path]) }
}
