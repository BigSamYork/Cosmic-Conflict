#ifndef Root
  #define Root ".."
#endif
#ifndef GameVersion
  #define GameVersion "1.0.0"
#endif
#ifndef ManualVersion
  #define ManualVersion GameVersion
#endif

[Setup]
#ifdef ValidationInstall
AppId={{1CE8AF01-9BA8-4C72-9447-F07C2A188E30}
AppName=Cosmic Conflict Installer Validation
DefaultDirName={localappdata}\Programs\Cosmic Conflict Installer Validation
DefaultGroupName=Cosmic Conflict Installer Validation
OutputDir={#Root}\releases\{#GameVersion}\validation\installer-lab
OutputBaseFilename=CosmicConflict-{#GameVersion}-Validation-Setup
CloseApplications=no
#else
AppId={{1D7ADBF0-7E66-4D44-95D8-AC8F910AC629}
AppName=Cosmic Conflict
DefaultDirName={localappdata}\Programs\Cosmic Conflict
DefaultGroupName=Cosmic Conflict
OutputDir={#Root}\releases\{#GameVersion}
OutputBaseFilename=CosmicConflict-{#GameVersion}-Setup
CloseApplications=yes
#endif
AppVersion={#GameVersion}
VersionInfoVersion={#GameVersion}.0
AppPublisher=Cosmic Conflict
; Retain existing installations through AppId and UsePreviousAppDir.
UsePreviousAppDir=yes
UsePreviousGroup=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#Root}\current_dev\cosmic-conflict.ico
UninstallDisplayIcon={app}\CosmicConflict.exe
DisableProgramGroupPage=yes
InfoBeforeFile={#Root}\Docs\FLIGHT_LAB.md

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#Root}\releases\{#GameVersion}\app\CosmicConflict.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Root}\releases\{#GameVersion}\app\CosmicConflict.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Root}\releases\{#GameVersion}\app\FLIGHT_LAB.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Root}\releases\{#GameVersion}\app\Cosmic_Conflict_Player_Manual_v{#ManualVersion}.docx"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Root}\releases\{#GameVersion}\app\LICENSES.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Root}\releases\{#GameVersion}\app\VoiceEditor.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Cosmic Conflict"; Filename: "{app}\CosmicConflict.exe"
Name: "{group}\Cosmic Conflict (OpenGL Compatibility)"; Filename: "{app}\CosmicConflict.exe"; Parameters: "--rendering-method gl_compatibility --rendering-driver opengl3"
Name: "{group}\Cosmic Conflict Voice Editor"; Filename: "{app}\CosmicConflict.exe"; Parameters: "--rendering-method gl_compatibility --rendering-driver opengl3 -- --voice-editor"
Name: "{group}\Uninstall Cosmic Conflict"; Filename: "{uninstallexe}"
#ifdef ValidationInstall
Name: "{userdesktop}\Cosmic Conflict Installer Validation"; Filename: "{app}\CosmicConflict.exe"; Tasks: desktopicon
#else
Name: "{userdesktop}\Cosmic Conflict"; Filename: "{app}\CosmicConflict.exe"; Tasks: desktopicon
#endif

[InstallDelete]
Type: files; Name: "{app}\CosmosConflict.exe"
Type: files; Name: "{app}\CosmosConflict.pck"
#ifndef ValidationInstall
Type: files; Name: "{userprograms}\Cosmos Conflict Flight Lab\Cosmos Conflict Flight Lab.lnk"
Type: files; Name: "{userprograms}\Cosmos Conflict Flight Lab\Cosmos Conflict (OpenGL Compatibility).lnk"
Type: files; Name: "{userprograms}\Cosmos Conflict Flight Lab\Uninstall Cosmos Conflict Flight Lab.lnk"
Type: dirifempty; Name: "{userprograms}\Cosmos Conflict Flight Lab"
#endif

[Run]
Filename: "{app}\CosmicConflict.exe"; Description: "Launch Cosmic Conflict"; Flags: nowait postinstall skipifsilent
