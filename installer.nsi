; WSL Distro Manager Installer Script

!include "MUI2.nsh"
!include "x64.nsh"

; Metadata
Name "WSL Distro Manager"
OutFile "WSLDistroManagerInstaller.exe"
InstallDir "$PROGRAMFILES64\WSL Distro Manager"
RequestExecutionLevel admin

; Branding
!define COMPANYNAME "Bostrot"
!define DESCRIPTION "WSL Distribution Management Tool"
VIProductVersion "1.8.15.0"
VIAddVersionKey "ProductName" "WSL Distro Manager"
VIAddVersionKey "CompanyName" "${COMPANYNAME}"
VIAddVersionKey "FileDescription" "${DESCRIPTION}"
VIAddVersionKey "FileVersion" "1.8.15"
VIAddVersionKey "ProductVersion" "1.8.15"

; Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "WSL Distro Manager Installer"
!define MUI_WELCOMEPAGE_TEXT "This installer will guide you through the installation of WSL Distro Manager."

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Main Section" SecMain
    SetOutPath "$INSTDIR"
    
    ; Check for 64-bit
    ${If} ${RunningX64}
        File /r "build\windows\x64\runner\Release\*"
    ${Else}
        MessageBox MB_OK "This application requires a 64-bit Windows system."
        Quit
    ${EndIf}
    
    ; Create shortcuts
    CreateShortcut "$SMPROGRAMS\WSL Distro Manager.lnk" "$INSTDIR\wsl2distromanager.exe"
    CreateShortcut "$DESKTOP\WSL Distro Manager.lnk" "$INSTDIR\wsl2distromanager.exe"
    
    ; Write uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
    ; Remove files
    RMDir /r "$INSTDIR"
    
    ; Remove shortcuts
    Delete "$SMPROGRAMS\WSL Distro Manager.lnk"
    Delete "$DESKTOP\WSL Distro Manager.lnk"
SectionEnd
