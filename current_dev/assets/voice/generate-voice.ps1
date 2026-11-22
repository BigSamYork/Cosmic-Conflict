param(
    [Parameter(Mandatory)][string]$CatalogPath,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [switch]$Overwrite
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
# A game launched from PowerShell 7 can inherit its incompatible module search path.
Import-Module ([IO.Path]::Combine($PSHOME, 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1'))
Import-Module ([IO.Path]::Combine($PSHOME, 'Modules\Microsoft.PowerShell.Management\Microsoft.PowerShell.Management.psd1'))
$catalogHash = (Get-FileHash -LiteralPath $catalogPath -Algorithm SHA256).Hash
$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if ($catalog.voice -isnot [string] -or [string]::IsNullOrWhiteSpace($catalog.voice)) { throw 'A voice name is required.' }
$ids = [Collections.Generic.HashSet[string]]::new()
$lines = @()
foreach ($section in $catalog.sections) {
    foreach ($line in $section.lines) {
        if ($line.id -notmatch '^[a-z][a-z0-9_-]*$' -or -not $ids.Add($line.id)) { throw 'Invalid or duplicate voice line ID.' }
        if ($line.event -notmatch '^[a-z_]+$' -or $line.text -isnot [string] -or [string]::IsNullOrWhiteSpace($line.text)) { throw "Invalid voice line: $($line.id)" }
        $lines += $line
    }
}
if ($lines.Count -eq 0) { throw 'The voice catalog has no lines.' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
foreach ($line in $lines) {
    $path = Join-Path $OutputDirectory ($line.id + '.wav')
    if ((Test-Path -LiteralPath $path) -and -not $Overwrite) { throw "Generated clip exists: $path. Use -Overwrite to regenerate named clips." }
}

$voice = New-Object -ComObject SAPI.SpVoice
$tokens = $null
$results = @()
try {
    $tokens = $voice.GetVoices()
    $selected = $false
    for ($i = 0; $i -lt $tokens.Count; $i++) {
        $token = $tokens.Item($i)
        try {
            if ($token.GetDescription().StartsWith($catalog.voice + ' -')) {
                $voice.Voice = $token
                $selected = $true
                break
            }
        } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($token) }
    }
    if (-not $selected) { throw "The requested offline voice is not installed: $($catalog.voice)" }
    $voice.Rate = 1
    $voice.Volume = 100
    foreach ($line in $lines) {
        $path = Join-Path $OutputDirectory ($line.id + '.wav')
        $stream = New-Object -ComObject SAPI.SpFileStream
        $opened = $false
        try {
            $stream.Format.Type = 22
            $stream.Open($path, 3, $false)
            $opened = $true
            $voice.AudioOutputStream = $stream
            [void]$voice.Speak($line.text, 16)
        } finally {
            if ($opened) { $stream.Close() }
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($stream)
        }
        $bytes = [IO.File]::ReadAllBytes($path)
        if ($bytes.Length -lt 1024 -or [Text.Encoding]::ASCII.GetString($bytes,0,4) -ne 'RIFF' -or [Text.Encoding]::ASCII.GetString($bytes,8,4) -ne 'WAVE') { throw "Invalid generated wave: $path" }
        $position = 12
        $rate = 0
        $dataLength = 0
        while ($position + 8 -le $bytes.Length) {
            $kind = [Text.Encoding]::ASCII.GetString($bytes,$position,4)
            $size = [BitConverter]::ToUInt32($bytes,$position + 4)
            $position += 8
            if ($position + $size -gt $bytes.Length) { throw "Truncated wave chunk: $path" }
            if ($kind -eq 'fmt ') {
                if ($size -lt 16 -or [BitConverter]::ToUInt16($bytes,$position) -ne 1 -or [BitConverter]::ToUInt16($bytes,$position+2) -ne 1 -or [BitConverter]::ToUInt16($bytes,$position+14) -ne 16) { throw "Expected mono PCM16 audio: $path" }
                $rate = [BitConverter]::ToUInt32($bytes,$position+4)
            } elseif ($kind -eq 'data') { $dataLength = $size }
            $position += $size + ($size % 2)
        }
        if ($rate -ne 22050 -or $dataLength -le 0) { throw "Invalid generated audio payload: $path" }
        $duration = $dataLength / ($rate * 2.0)
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $textHash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($line.text))).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        $results += @{id=$line.id; event=$line.event; text_sha256=$textHash; seconds=[math]::Round($duration,3); bytes=$bytes.Length}
        Write-Output ("VOICE_CLIP {0} {1:N2}s" -f $line.id,$duration)
    }
} finally {
    if ($null -ne $tokens) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($tokens) }
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($voice)
}
if ((Get-FileHash -LiteralPath $catalogPath -Algorithm SHA256).Hash -ne $catalogHash) { throw 'Voice catalog changed during synthesis; generated audio needs regeneration.' }
@{voice=$catalog.voice; catalog_sha256=$catalogHash; rate=22050; channels=1; clips=$results} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'generated-voice.json') -Encoding utf8
Write-Output "VOICE_GENERATION_COMPLETE=$($results.Count)"
