; Inno Setup script for the Windows installer. Build it with:
;   ISCC /DAppVersion=1.2.3 /DSourceDir=<release folder> installer\kina_calculator.iss
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\app\build\windows\x64\runner\Release"
#endif

[Setup]
; Keep this id the same in every release so an install upgrades the last one.
AppId={{480BCFCD-2CAD-4E7A-9E86-8C9762DAA8B1}
AppName=Kina Calculator
AppVersion={#AppVersion}
AppPublisher=SarunasKir
DefaultDirName={autopf}\Kina Calculator
DefaultGroupName=Kina Calculator
UninstallDisplayIcon={app}\kina_app.exe
OutputDir=..\dist
OutputBaseFilename=KinaCalculator-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Installs for the current user without an administrator prompt; the setup
; offers an all-users install as an option.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kina Calculator"; Filename: "{app}\kina_app.exe"
Name: "{autodesktop}\Kina Calculator"; Filename: "{app}\kina_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kina_app.exe"; Description: "Start Kina Calculator"; Flags: nowait postinstall skipifsilent
