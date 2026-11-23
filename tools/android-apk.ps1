# The Windows release runner uses the Godot APK template directly, without Gradle.
function Get-AndroidSdk([string]$Requested) {
    $candidates = if ($Requested) { @($Requested) } else {
        @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, "$env:ANDROID_HOME/Sdk", "$env:LOCALAPPDATA/Android/Sdk")
    }
    foreach ($dir in $candidates) {
        if ($dir -and (Test-Path -LiteralPath "$dir/platform-tools/adb.exe")) { return (Resolve-Path $dir).Path }
    }
    throw 'Android SDK missing. Supply -AndroidSdk or set ANDROID_HOME.'
}

function Get-AndroidBuildTools([string]$Sdk) {
    $dir = Get-ChildItem -LiteralPath "$Sdk/build-tools" -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' -and [version]$_.Name -ge [version]'35.0.0' } |
        Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
    if (-not $dir) { throw 'Install Android SDK Build-Tools 35.0.0 or newer.' }
    return $dir.FullName
}

function Export-AndroidApk([string]$Sdk, [string]$Stage, [string]$GodotVersion) {
    $profile = Join-Path $Stage 'profile'
    $settings = New-Item -ItemType Directory -Force "$profile/Godot"
    $majorMinor = ([version]($GodotVersion -split '-')[0]).ToString(2)
    if (-not (Test-Path -LiteralPath "$env:JAVA_HOME/bin/keytool.exe")) { throw 'Set JAVA_HOME to an installed JDK.' }
    $lines = @('[gd_resource type="EditorSettings" format=3]', '[resource]',
        ('export/android/android_sdk_path = "' + $Sdk.Replace('\','/') + '"'),
        ('export/android/java_sdk_path = "' + $env:JAVA_HOME.Replace('\','/') + '"'))
    [IO.File]::WriteAllLines("$($settings.FullName)/editor_settings-$majorMinor.tres", $lines)
    $previous = $env:APPDATA
    try {
        $env:APPDATA = $profile
        Invoke-Godot @('--headless', '--path', $project, '--export-release', 'Android', "$Stage/export.apk")
    } finally { $env:APPDATA = $previous }
    $tools = Get-AndroidBuildTools $Sdk
    & "$tools/zipalign.exe" -P 16 -f 4 "$Stage/export.apk" "$Stage/aligned.apk"
    if ($LASTEXITCODE -ne 0) { throw 'Android APK alignment failed.' }
}

function Write-SignedApk([string]$Sdk, [string]$Aligned, [string]$Destination, [switch]$Preview) {
    $tools = Get-AndroidBuildTools $Sdk
    $keystore = $env:ANDROID_RELEASE_KEYSTORE
    $alias = $env:ANDROID_KEY_ALIAS
    $passwords = @('--ks-pass', 'env:ANDROID_KEYSTORE_PASSWORD', '--key-pass', 'env:ANDROID_KEYSTORE_PASSWORD')
    if ($env:ANDROID_KEY_PASSWORD) { $passwords[-1] = 'env:ANDROID_KEY_PASSWORD' }
    if ($Preview) {
        $keystore = Join-Path (Split-Path $Aligned) 'preview.p12'
        $alias = 'preview'
        & "$env:JAVA_HOME/bin/keytool.exe" -genkeypair -storetype PKCS12 -keystore $keystore -alias $alias -dname 'CN=Cosmic Conflict Preview' -keyalg RSA -keysize 2048 -validity 30 -storepass android -keypass android
        if ($LASTEXITCODE -ne 0) { throw 'Preview key generation failed.' }
        $passwords = @('--ks-pass', 'pass:android', '--key-pass', 'pass:android')
    } elseif (-not ($keystore -and $alias -and $env:ANDROID_KEYSTORE_PASSWORD)) {
        throw 'Set ANDROID_RELEASE_KEYSTORE, ANDROID_KEY_ALIAS and ANDROID_KEYSTORE_PASSWORD for release signing, or use -AndroidPreview.'
    }
    $signed = Join-Path (Split-Path $Aligned) 'signed.apk'
    & "$tools/apksigner.bat" sign --ks $keystore --ks-key-alias $alias @passwords --v4-signing-enabled false --out $signed $Aligned
    if ($LASTEXITCODE -ne 0) { throw 'APK signing failed.' }
    & "$tools/apksigner.bat" verify --verbose $signed
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    & "$tools/zipalign.exe" -c -P 16 4 $signed
    if ($LASTEXITCODE -ne 0) { throw 'Signed APK alignment verification failed.' }
    Move-Item -LiteralPath $signed -Destination $Destination -Force
}
