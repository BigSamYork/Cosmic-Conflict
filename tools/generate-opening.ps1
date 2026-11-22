# Run with Windows PowerShell and the offline SAPI desktop voices.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$script = Get-Content (Join-Path $root 'current_dev/assets/voice/opening.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$folder = Join-Path $root 'current_dev/assets/opening'
[void][IO.Directory]::CreateDirectory($folder)
Add-Type -AssemblyName System.Speech
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    foreach ($cue in $script.cues) {
        $actor = $script.cast.($cue.speaker)
        $voice.SelectVoice($actor.voice)
        $voice.Rate = if ($cue.PSObject.Properties['rate']) { $cue.rate } else { $actor.rate }
        $voice.SetOutputToWaveFile((Join-Path $folder ($cue.id + '.wav')), $format)
        $voice.Speak($cue.text)
        $voice.SetOutputToNull()
    }
} finally { $voice.Dispose() }
