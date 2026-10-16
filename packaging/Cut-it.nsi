; Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
Unicode True
!include "MUI2.nsh"
Name "Cut-it 0.1.1"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\Cut-it"
InstallDirRegKey HKCU "Software\Cut-it" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
!define MUI_ABORTWARNING
!define MUI_ICON "windows\cut-it.ico"
!define MUI_UNICON "windows\cut-it.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PACKAGE}\COPYING"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"
; Check before copying any files. Never terminate an editor with unsaved work.
Function EnsureEditorClosed
 retry:
 IfFileExists "$INSTDIR\runtime\shotcut.exe" 0 ready
 ClearErrors
 FileOpen $0 "$INSTDIR\runtime\shotcut.exe" a
 IfErrors busy
 FileClose $0
 Goto ready
 busy:
 IfSilent cancel
 MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Cut-it is still running. Save your work and close every Cut-it window before updating. Then click Retry." IDRETRY retry
 cancel:
 SetErrorLevel 2
 Quit
 ready:
FunctionEnd
Section "Cut-it"
 Call EnsureEditorClosed
 SetOutPath "$INSTDIR"
 File /r "${PACKAGE}\*"
 WriteUninstaller "$INSTDIR\Uninstall.exe"
 CreateDirectory "$SMPROGRAMS\Cut-it"
 CreateShortcut "$SMPROGRAMS\Cut-it\Cut-it.lnk" "$INSTDIR\Cut-it.exe"
 CreateShortcut "$DESKTOP\Cut-it.lnk" "$INSTDIR\Cut-it.exe"
 WriteRegStr HKCU "Software\Cut-it" "InstallDir" "$INSTDIR"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cut-it" "DisplayName" "Cut-it 0.1.1"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cut-it" "DisplayVersion" "0.1.1"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cut-it" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
 WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cut-it" "NoModify" 1
 WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cut-it" "NoRepair" 1
SectionEnd
Section "Uninstall"
 Delete "$DESKTOP\Cut-it.lnk"
 Delete "$SMPROGRAMS\Cut-it\Cut-it.lnk"
 RMDir "$SMPROGRAMS\Cut-it"
 RMDir /r "$INSTDIR\runtime"
 RMDir /r "$INSTDIR\lib"
 RMDir /r "$INSTDIR\share"
 RMDir /r "$INSTDIR\Licenses"
 Delete "$INSTDIR\Cut-it.exe"
 Delete "$INSTDIR\Cut-it.ico"
 Delete "$INSTDIR\COPYING"
 Delete "$INSTDIR\CUT-IT.md"
 Delete "$INSTDIR\Build-packages.txt"
 Delete "$INSTDIR\README.txt"
 Delete "$INSTDIR\Cut-it-source.zip"
 Delete "$INSTDIR\Uninstall.exe"
 RMDir "$INSTDIR"
 DeleteRegKey HKCU "Software\Cut-it"
 DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cut-it"
SectionEnd
