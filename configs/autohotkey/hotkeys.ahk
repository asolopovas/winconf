#Include helpers/runasuser.ahk

RestartExplorer(delay=-1) {
    If (A_OSVersion != "WIN_XP") {
        WinGet, PID, PID, 	 ahk_class Shell_TrayWnd
        PostMessage, 0x5B4, 0, 0, , ahk_class Shell_TrayWnd ; WM_USER + 0x1B4
        PostMessage, 0x111, 518, 0,, ahk_class Shell_TrayWnd ; thanks SKAN, but needs more testing on win10
    } Else {
        WinGet, PID, PID, ahk_class Progman
        PostMessage, 0x012, 0, 0, , ahk_class Progman ; WM_QUIT = 0x12   ; ExitExplorer2
        PostMessage, 0x012, 0, 1, , ahk_class Progman ; WM_QUIT = 0x12   ; ExitExplorer1
        PostMessage, 0x012, 0, 0, , ahk_class Shell_TrayWnd ; WM_QUIT = 0x12
    }
    RunWait taskkill /F /IM explorer.exe,, Hide
    Sleep, %delay%
    If ((A_OSVersion != "WIN_XP") && A_IsAdmin) {
        hMod := DllCall("LoadLibrary", Str, "wdc.dll", Ptr)
        WdcRunAsIU := DllCall("GetProcAddress", Ptr, hMod, AStr, "WdcRunTaskAsInteractiveUser", Ptr)
        DllCall(WdcRunAsIU, WStr, "%windir%\explorer.exe", Ptr, 0, UInt, 9, UInt)
        DllCall("FreeLibrary", Ptr, hMod)
    } Else
        Run %A_WinDir%\explorer.exe, %A_WinDir%\system32, UseErrorLevel
}

+F12::
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
    DllCall("LockWorkStation")
    sleep, 1000
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
return

#+x::
    RestartExplorer()
Return

#f::
    WinGet MMX, MinMax, A
    IfEqual MMX,0, WinMaximize, A
    IfEqual MMX,1, WinRestore, A
Return

F10::
    EnvGet, username, username
    itemClass := "Administrator: PowerShell"
    terminalExe := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    if WinExist(itemClass) {
        If WinActive(itemClass) {
            WinMinimize
        } else {
            WinActivate
        }
    } else {
        Run, %terminalExe%
        WinActivate
    }
Return

#+o::
    EnvGet, username, username
    itemClass := "fzfmenu"
    cmd := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    args := "--title " itemClass " --suppressApplicationTitle powershell -NoProfile -NoLogo -Command ""folderCode"""
    RunAsUser(cmd, args)
    WinWait fzfmenu ahk_class CASCADIA_HOSTING_WINDOW_CLASS
    WinActivate
Return

#o::
    EnvGet, username, username
    cmd := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    args := "--title fzfmenu --suppressApplicationTitle wsl -d Ubuntu bash -c '/home/andrius/.local/bin/helpers/folder-cmd code'"
    RunAsUser(cmd, args)
    WinWait fzfmenu ahk_class CASCADIA_HOSTING_WINDOW_CLASS
    WinActivate
Return


#p::
    EnvGet, username, username
    cmd := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    args := "--title fzfmenu --suppressApplicationTitle wsl -d Ubuntu bash -c '/home/andrius/.local/bin/helpers/folder-cmd phpstorm64.exe'"
    RunAsUser(cmd, args)
    WinWait fzfmenu ahk_class CASCADIA_HOSTING_WINDOW_CLASS
    WinActivate
Return

;--------------------------------------
; Application Shortuts
; --------------------------------------

#c::
    itemClass := "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"
    if WinExist(itemClass) {
        If WinActive(itemClass){
            WinMinimize
        } else {
            WinActivate
        }
    } else {
        RunAsUser("C:\Program Files\Google\Chrome\Application\chrome.exe")
    }
Return

#m::
    spotifyClass := "ahk_class Chrome_WidgetWin_0 ahk_exe Spotify.exe"
    spotifyPath := A_AppData "\Spotify\Spotify.exe"

    if !FileExist(spotifyPath) {
        winget install --id Spotify.Spotify

        ; Wait for winget to finish installation
        ; Assumes that winget's executable name is 'winget.exe'
        WinWait, ahk_exe winget.exe
        WinWaitClose, ahk_exe winget.exe
    }

    if WinExist(spotifyClass) {
        if WinActive(spotifyClass)
            PostMessage, 0x112, 0xF060,,, % "ahk_id " WinActive("A")
        else
            WinActivate
    } else {
        Run, % spotifyPath
    }
Return


#+Enter::
    EnvGet, username, username
    windowTitle := "Ubuntu"
    args := "-w Ubuntu nt -p Ubuntu --title Ubuntu --suppressApplicationTitle"
    if WinExist(windowTitle) {
        If WinActive(windowTitle)
            RunAsUser("C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe", args)
        else
            WinActivate
        return
    } else {
        RunAsUser("C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe", args)
        return
    }
return

#Enter::
    EnvGet, username, username
    windowTitle := "PowerShell"
    args := "-w PowerShell nt -p PowerShell --title PowerShell --suppressApplicationTitle"
    if WinExist(windowTitle) {
        If WinActive(windowTitle)
            RunAsUser("C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe", args)
        else
            WinActivate
        return
    } else {
        RunAsUser("C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe", args)
        WinWait PowerShell ahk_class CASCADIA_HOSTING_WINDOW_CLASS
        WinActivate
        return
    }

#q::
    WinGetTitle, Title, A
    PostMessage, 0x112, 0xF060,,, %Title%
return

; --------------------------------------
; Navigation
; --------------------------------------
#h::#Left
#j::#Down
#k::#Up
#l::#Right

LWin & i::AltTab
LWin & u::ShiftAltTab
