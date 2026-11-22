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
if (Test-Path -LiteralPath (Join-Path $project 'scripts\computer_voice.gd')) {
    $voiceIndex = Join-Path $project 'assets\voice\generated-voice.json'
    if (-not (Test-Path -LiteralPath $voiceIndex)) { throw 'Voice recordings are not generated. Run tools\generate-voice.ps1.' }
    $voiceProof = Get-Content -LiteralPath $voiceIndex -Raw | ConvertFrom-Json
    $voiceCatalog = Get-Content -LiteralPath (Join-Path $project 'assets\voice\lines.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($voiceProof.voice -ne $voiceCatalog.voice) { throw 'Voice changed. Run tools\generate-voice.ps1 -Overwrite before building.' }
    foreach ($line in $voiceCatalog.sections.lines) {
        $clip = @($voiceProof.clips | Where-Object id -eq $line.id)
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $textHash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($line.text))).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        if ($clip.Count -ne 1 -or -not $clip[0].PSObject.Properties['text_sha256'] -or $clip[0].text_sha256 -ne $textHash) { throw 'Voice dialogue changed. Run tools\generate-voice.ps1 -Overwrite before building.' }
    }
    foreach ($clip in $voiceProof.clips) {
        $clipPath = Join-Path $project ("assets\voice\{0}.wav" -f $clip.id)
        if (-not (Test-Path -LiteralPath $clipPath) -or (Get-Item -LiteralPath $clipPath).Length -ne $clip.bytes) { throw "Voice recording is missing or changed: $clipPath" }
    }
}
if (Test-Path -LiteralPath (Join-Path $project 'scripts\ambient_music.gd')) {
    $musicIndex = Join-Path $project 'assets\music\generated-music.json'
    if (-not (Test-Path -LiteralPath $musicIndex)) { throw 'Original music is missing. Run Godot with --headless --path current_dev --script tools\generate-music.gd (absolute script path).' }
    $musicProof = Get-Content -LiteralPath $musicIndex -Raw | ConvertFrom-Json
    if ($musicProof.generator_sha256 -ne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'generate-music.gd')).Hash) { throw 'Music generator changed. Regenerate the original recordings before building.' }
    foreach ($track in $musicProof.tracks) {
        $trackPath = Join-Path $project ("assets\music\{0}.wav" -f $track.id)
        if (-not (Test-Path -LiteralPath $trackPath) -or (Get-FileHash -LiteralPath $trackPath).Hash -ne $track.sha256) { throw "Original music is missing or changed: $trackPath" }
    }
}
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
