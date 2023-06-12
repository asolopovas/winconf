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

#h::#Left
#j::#Down
#k::#Up
#l::#Right

LWin & i::AltTab
LWin & u::ShiftAltTab

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
        RunAsUser("winget install --id Spotify.Spotify")
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

#f::
    WinGet MMX, MinMax, A
    IfEqual MMX,0, WinMaximize, A
    IfEqual MMX,1, WinRestore, A
Return

#q::
    WinGetTitle, Title, A
    PostMessage, 0x112, 0xF060,,, %Title%
return

#Enter::
    RunOrActivateTerminal("PowerShell", false)
return

!Enter::
    RunOrActivateTerminal("Ubuntu", false)
return

#+Enter::
    RunOrActivateTerminal("PowerShell", true)
return

!+Enter::
    RunOrActivateTerminal("Ubuntu", true)
return

RunOrActivateTerminal(windowTitle, alwaysNewInstance) {
    EnvGet, username, username
    terminalPath := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    args := "-w " windowTitle " nt -p " windowTitle " --title " windowTitle " --suppressApplicationTitle"
    windowID := windowTitle " ahk_class CASCADIA_HOSTING_WINDOW_CLASS"

    if WinExist(windowTitle) and !alwaysNewInstance {
        WinActivate, %windowID%
    } else {
        RunAsUser(terminalPath, args)
        WinWait, %windowID%
        WinActivate, %windowID%
    }
}


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

+F12::
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
    DllCall("LockWorkStation")
    sleep, 1000
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
return

^F12::
    RestartExplorer()
Return
