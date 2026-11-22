param(
    [ValidateRange(1, 240)][int]$Minutes = 120,
    [string]$Version
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Content (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
if (-not $Version) { $Version = $config.game_version }
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Version must be a release number such as 0.7.0.' }
$release = Join-Path $root "releases\$Version"
$binary = if ([version]$Version -lt [version]'0.9.0') { 'CosmosConflict.exe' } else { 'CosmicConflict.exe' }
$Executable = Join-Path $release ("app\" + $binary)
if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) { throw "Missing game export: $Executable" }
$output = Join-Path $release ('validation\soak-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $output | Out-Null
$summary = Join-Path $output 'results.jsonl'
$clock = [Diagnostics.Stopwatch]::StartNew()
$results = [Collections.Generic.List[object]]::new()
$process = $null
Write-Output ("SOAK_START time={0:o} minutes={1} output={2}" -f (Get-Date), $Minutes, $output)
try {
    $index = 0
    while ($clock.Elapsed.TotalMinutes -lt $Minutes) {
        $renderer = @('vulkan', 'opengl')[$index % 2]
        $fps = @(30, 45)[[int][Math]::Floor($index / 2) % 2]
        $ship = @('rook', 'hawk', 'emergency')[[int][Math]::Floor($index / 4) % 3]
        $reduced = ([int][Math]::Floor($index / 12) % 2) -eq 1
        $label = '{0:D2}-{1}-{2}-{3}-{4}' -f $index, $renderer, $fps, $ship, $(if ($reduced) { 'reduced' } else { 'normal' })
        $log = Join-Path $output ($label + '.log')
        $stdout = Join-Path $output ($label + '-stdout.log')
        $stderr = Join-Path $output ($label + '-stderr.log')
        $save = Join-Path $output ($label + '-state.json')
        $arguments = @('--fullscreen', '--max-fps', "$fps", '--log-file', $log)
        if ($renderer -eq 'opengl') { $arguments += @('--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3') }
        $arguments += @('--', '--mission-test', '--real-time', "--validation-ship=$ship", "--campaign-save=$save")
        if ($reduced) { $arguments += '--reduced-effects' }
        $started = Get-Date
        Write-Output ("RUN_START {0} {1:o}" -f $label, $started)
        $process = Start-Process -FilePath $Executable -ArgumentList ($arguments | ForEach-Object { '"' + $_ + '"' }) -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $ready = $false
        for ($attempt = 0; $attempt -lt 45; $attempt++) {
            if ($process.WaitForExit(1000)) { break }
            $process.Refresh()
            # Unfocusable validation windows may not have a .NET MainWindowHandle.
            if ((Test-Path -LiteralPath $stdout) -and (Select-String -LiteralPath $stdout -Pattern '^VALIDATION_PROFILE' -Quiet)) {
                $ready = $true
                break
            }
        }
        if ($ready) { Write-Output ("RUN_READY {0} pid={1}" -f $label, $process.Id) }
        $reason = ''
        if (-not $ready) {
            $reason = 'Native renderer and validation startup were not confirmed within 45 seconds.'
            if (-not $process.HasExited) { Stop-Process -Id $process.Id }
        } elseif (-not $process.WaitForExit(660000)) {
            $reason = 'Mission exceeded its eleven-minute wall-clock limit.'
            Stop-Process -Id $process.Id
        }
        $text = if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Raw } else { '' }
        if (Test-Path -LiteralPath $stderr) { $text += Get-Content -LiteralPath $stderr -Raw }
        if (-not $reason -and ($process.ExitCode -ne 0 -or $text -match '(?m)SCRIPT ERROR:|^ERROR:|FAIL:' -or $text -notmatch 'AUTOMATION_FAILURES=0')) {
            $reason = 'Game exit/log did not pass all mission assertions.'
        }
        $result = [ordered]@{
            scenario = $label
            started = $started.ToString('o')
            completed = (Get-Date).ToString('o')
            seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 2)
            passed = $reason -eq ''
            reason = $reason
            log = $log
        }
        $results.Add($result)
        $result | ConvertTo-Json -Compress | Add-Content -LiteralPath $summary
        Write-Output ('RUN_RESULT ' + ($result | ConvertTo-Json -Compress))
        if (Test-Path -LiteralPath $save) { Remove-Item -LiteralPath $save }
        if (Test-Path -LiteralPath ($save + '.tmp')) { Remove-Item -LiteralPath ($save + '.tmp') }
        $process.Dispose()
        $process = $null
        $index++
    }
} finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id }
        $process.Dispose()
    }
}
$failures = @($results | Where-Object { -not $_.passed }).Count
Write-Output ("SOAK_COMPLETE runs={0} failures={1} minutes={2:F2} summary={3}" -f $results.Count, $failures, $clock.Elapsed.TotalMinutes, $summary)
if ($failures -gt 0) { throw "$failures extended-validation scenarios failed; inspect $summary." }
