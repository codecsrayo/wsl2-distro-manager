; WSL Distro Manager Installer Script

!include "MUI2.nsh"
!include "x64.nsh"
!include "FileFunc.nsh"

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
VIAddVersionKey "LegalCopyright" "Copyright (C) 2023 Eric Trenkel"

; Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "WSL Distro Manager Installer"
!define MUI_WELCOMEPAGE_TEXT "This installer will guide you through the installation of WSL Distro Manager."

; Icons for installer and uninstaller
!define MUI_ICON "windows\runner\resources\app_icon.ico"
!define MUI_UNICON "windows\runner\resources\app_icon.ico"

; Pages for installer
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Pages for uninstaller
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Spanish"

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
    
    ; Create directory in Start Menu
    CreateDirectory "$SMPROGRAMS\WSL Distro Manager"
    CreateShortcut "$SMPROGRAMS\WSL Distro Manager\WSL Distro Manager.lnk" "$INSTDIR\wsl2distromanager.exe"
    CreateShortcut "$SMPROGRAMS\WSL Distro Manager\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    
    ; Write uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; Write registry information for Add/Remove Programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "DisplayName" "WSL Distro Manager"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "DisplayVersion" "1.8.15"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "NoRepair" 1
    
    ; Estimate size
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager" "EstimatedSize" "$0"
SectionEnd

Section "Uninstall"
    ; Remove files
    RMDir /r "$INSTDIR"
    
    ; Remove shortcuts
    Delete "$SMPROGRAMS\WSL Distro Manager.lnk"
    Delete "$DESKTOP\WSL Distro Manager.lnk"
    
    ; Remove Start Menu folder and shortcuts
    Delete "$SMPROGRAMS\WSL Distro Manager\WSL Distro Manager.lnk"
    Delete "$SMPROGRAMS\WSL Distro Manager\Uninstall.lnk"
    RMDir "$SMPROGRAMS\WSL Distro Manager"
    
    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WSLDistroManager"
SectionEnd
