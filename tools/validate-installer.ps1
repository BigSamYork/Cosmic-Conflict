#requires -Version 7.0
param(
    [string]$PreviousVersion = '0.19.4',
    [string]$Version,
    [string]$Iscc
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
if (-not $Version) { $Version = $config.game_version }
foreach ($number in @($Version, $PreviousVersion)) {
    if ($number -notmatch '^\d+\.\d+\.\d+$') { throw 'Installer validation requires numeric release versions.' }
}
if ($Version -eq $PreviousVersion) { throw 'Upgrade validation requires distinct previous and candidate versions.' }
if (-not $Iscc) { $Iscc = Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe' }
$lab = Join-Path $root "releases\$Version\validation\installer-lab"
$installed = Join-Path $lab 'InstalledGame'
$userData = Join-Path $lab 'user-data'
$testKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{1CE8AF01-9BA8-4C72-9447-F07C2A188E30}_is1'
$normalKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{1D7ADBF0-7E66-4D44-95D8-AC8F910AC629}_is1'
$group = Join-Path ([Environment]::GetFolderPath('Programs')) 'Cosmic Conflict Installer Validation'
$desktop = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Cosmic Conflict Installer Validation.lnk'
if ((Test-Path -LiteralPath $installed) -or (Test-Path -LiteralPath $testKey) -or (Test-Path -LiteralPath $group) -or (Test-Path -LiteralPath $desktop)) {
    throw 'An earlier installer-validation location or registration exists. Inspect it before retrying; it will not be overwritten.'
}
function Normal-Registration {
    if (Test-Path -LiteralPath $normalKey) {
        return (Get-ItemProperty -LiteralPath $normalKey | Select-Object DisplayVersion, InstallLocation, UninstallString | ConvertTo-Json -Compress)
    }
    return 'absent'
}
$normalRegistration = Normal-Registration
$normalFiles = @{}
$normalDesktop = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Cosmic Conflict.lnk'
$normalFiles[$normalDesktop] = if (Test-Path -LiteralPath $normalDesktop) { (Get-FileHash -LiteralPath $normalDesktop).Hash } else { 'absent' }
$saveFolder = Join-Path $env:APPDATA 'Cosmos Conflict'
foreach ($name in @('campaign.json', 'settings.cfg', 'hall_of_fame.json')) {
    $path = Join-Path $saveFolder $name
    $normalFiles[$path] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path).Hash } else { 'absent' }
}
if (Test-Path -LiteralPath $normalKey) {
    $normalDirectory = (Get-ItemProperty -LiteralPath $normalKey).InstallLocation
    if (-not [string]::IsNullOrWhiteSpace($normalDirectory)) {
        foreach ($name in @('CosmicConflict.exe', 'CosmicConflict.pck', 'FLIGHT_LAB.md', 'LICENSES.txt')) {
            $path = Join-Path $normalDirectory $name
            $normalFiles[$path] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path).Hash } else { 'absent' }
        }
    }
}
New-Item -ItemType Directory -Force -Path $lab, $userData | Out-Null
function Run-Owned([string]$Executable, [string[]]$Arguments, [string]$Label, [int]$Timeout = 150) {
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    if ($Label -like '*game*') { $info.Environment['APPDATA'] = $userData }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    $started = $false
    try {
        $started = $process.Start()
        Write-Output "INSTALLER_TEST_START label=$Label owned_pid=$($process.Id)"
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($Timeout * 1000)) { throw "$Label exceeded its bounded timeout." }
        $output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
        $output | Set-Content -LiteralPath (Join-Path $lab "$Label.log")
        if ($process.ExitCode -ne 0 -or $output -match '(?m)^ERROR:|SCRIPT ERROR:|FAIL:') { throw "$Label failed; inspect its retained log." }
        if ($Label -like '*game*' -and $output -notmatch 'AUTOMATION_FAILURES=0') { throw "$Label exited without successful gameplay verification." }
        Write-Output "INSTALLER_TEST_PASS label=$Label"
    } finally {
        if ($started -and -not $process.HasExited) { Stop-Process -Id $process.Id }
        $process.Dispose()
    }
}
$seed = Join-Path $userData 'campaign.json'
$engine = Join-Path $root ".tools\godot\Godot_v$($config.godot)_win64_console.exe"
$output = & $engine --headless --path (Join-Path $root 'current_dev') --script 'res://tests/test_release_polish.gd' -- "--fixture-output=$seed" 2>&1
$output | Set-Content -LiteralPath (Join-Path $lab 'fixture.log')
if ($LASTEXITCODE -ne 0 -or $output -match 'SCRIPT ERROR:|^ERROR:' -or -not ($output -match '^INSTALLER_FIXTURE_FAILURES=0$')) { throw 'Could not create an isolated valid campaign fixture.' }
# Both the previous release and the expansion can read this unfinished legacy save.
$fixture = Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json -AsHashtable
if ($fixture.schema -notin @(11, 12)) { throw 'Review the installer fixture for the current campaign schema.' }
$fixture.schema = 11
[void]$fixture.Remove('required_sectors')
$fixture | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $seed
$namedGame = "$seed.slot-Release Check.json"
Copy-Item -LiteralPath $seed -Destination $namedGame
$preferences = Join-Path $userData 'settings.cfg'
$records = Join-Path $userData 'hall_of_fame.json'
"[flight_lab]`nvoice_volume=25`nmusic_volume=20`nmute=true`n" | Set-Content -LiteralPath $preferences
'{"schema":1,"records":[]}' | Set-Content -LiteralPath $records
$preserved = @{}
foreach ($path in @($seed, $namedGame, $preferences, $records)) { $preserved[$path] = (Get-FileHash -LiteralPath $path).Hash }
foreach ($release in @($PreviousVersion, $Version)) {
    foreach ($name in @('CosmicConflict.exe', 'CosmicConflict.pck', 'FLIGHT_LAB.md', 'LICENSES.txt')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root "releases\$release\app\$name"))) { throw "Missing $release installer payload: $name" }
    }
    Run-Owned $Iscc @("/DRoot=$root", "/DGameVersion=$release", '/DValidationInstall=1', (Join-Path $PSScriptRoot 'installer.iss')) "compile-$release"
    $setup = Join-Path $root "releases\$release\validation\installer-lab\CosmicConflict-$release-Validation-Setup.exe"
    $taskArguments = if ($release -eq $Version) { @('/TASKS=desktopicon') } else { @() }
    $setupArguments = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=$installed", '/GROUP=Cosmic Conflict Installer Validation', "/LOG=$(Join-Path $lab "install-$release.log")") + $taskArguments
    Run-Owned $setup $setupArguments "setup-$release"
    if (-not (Test-Path -LiteralPath $testKey)) { throw 'Validation installation did not register its own uninstaller.' }
    if ((Get-ItemProperty -LiteralPath $testKey).DisplayVersion -ne $release) { throw 'Registered test version does not match the installed release.' }
    foreach ($name in @('CosmicConflict.exe', 'CosmicConflict.pck', 'FLIGHT_LAB.md', 'LICENSES.txt', "Cosmic_Conflict_Player_Manual_v$release.docx")) {
        if ((Get-FileHash -LiteralPath (Join-Path $installed $name)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root "releases\$release\app\$name")).Hash) {
            throw "Installed $name differs from the verified release payload."
        }
    }
    $shell = New-Object -ComObject WScript.Shell
    try {
        foreach ($name in @('Cosmic Conflict', 'Cosmic Conflict (OpenGL Compatibility)')) {
            $shortcut = $shell.CreateShortcut((Join-Path $group "$name.lnk"))
            if ($shortcut.TargetPath -ne (Join-Path $installed 'CosmicConflict.exe')) { throw 'Validation shortcut points outside its own installation.' }
            if ($name -like '*OpenGL*' -and $shortcut.Arguments -notmatch 'gl_compatibility') { throw 'Compatibility shortcut is missing its renderer option.' }
        }
        if ($release -eq $Version) {
            if (-not (Test-Path -LiteralPath $desktop)) { throw 'Selected desktop-icon task did not create its shortcut.' }
            $shortcut = $shell.CreateShortcut($desktop)
            if ($shortcut.TargetPath -ne (Join-Path $installed 'CosmicConflict.exe') -or $shortcut.Arguments -ne '') { throw 'Desktop shortcut does not launch the isolated game normally.' }
        } elseif (Test-Path -LiteralPath $desktop) {
            throw 'Unselected desktop-icon task unexpectedly created a shortcut.'
        }
    } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) }
    Run-Owned (Join-Path $installed 'CosmicConflict.exe') @('--headless', '--', '--smoke-test', "--campaign-save=$seed") "game-$release"
    foreach ($path in $preserved.Keys) {
        if ((Get-FileHash -LiteralPath $path).Hash -ne $preserved[$path]) { throw "Install/upgrade altered retained user data: $path" }
    }
}
Run-Owned (Join-Path $installed 'unins000.exe') @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=$(Join-Path $lab 'uninstall-engine.log')") 'uninstall-driver'
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    if (-not (Test-Path -LiteralPath $testKey) -and -not (Test-Path -LiteralPath $group) -and -not (Test-Path -LiteralPath $desktop) -and -not (Test-Path -LiteralPath $installed)) { break }
    Start-Sleep -Seconds 1
}
if ((Test-Path -LiteralPath $testKey) -or (Test-Path -LiteralPath $group) -or (Test-Path -LiteralPath $desktop) -or (Test-Path -LiteralPath $installed)) {
    throw 'Uninstall left its application, shortcuts or test registration behind.'
}
foreach ($path in $preserved.Keys) {
    if ((Get-FileHash -LiteralPath $path).Hash -ne $preserved[$path]) { throw 'Uninstall changed retained saves, settings or Hall of Fame records.' }
}
if ((Normal-Registration) -ne $normalRegistration) { throw 'Normal installation registration changed during isolated validation.' }
foreach ($path in $normalFiles.Keys) {
    $actual = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path).Hash } else { 'absent' }
    if ($actual -ne $normalFiles[$path]) { throw "Normal installation or user data changed during validation: $path" }
}
[ordered]@{
    previous_version = $PreviousVersion
    candidate_version = $Version
    fresh_install = $true
    upgrade = $true
    installed_game_smoke_checks = $true
    desktop_icon_opt_in_verified = $true
    unselected_desktop_icon_absent = $true
    desktop_icon_removed_on_uninstall = $true
    uninstall = $true
    user_data_preserved = $true
    normal_installation_registration_unchanged = $true
    normal_payload_and_data_unchanged = $true
    clean_machine_verified = $false
    limitation = 'Isolated installer identity on this Windows machine; no clean Windows VM was available.'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $lab 'results.json')
foreach ($path in $preserved.Keys) { Remove-Item -LiteralPath $path }
Write-Output 'INSTALLER_VALIDATION_FAILURES=0'
