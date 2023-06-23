#Include helpers/runasuser.ahk
#Include hotkeys-apps.ahk

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

LWin & .::AltTab
LWin & ,::ShiftAltTab

#f::
    WinGet MMX, MinMax, A
    IfEqual MMX,0, WinMaximize, A
    IfEqual MMX,1, WinRestore, A
Return

#q::
    WinGetTitle, Title, A
    PostMessage, 0x112, 0xF060,,, %Title%
return



#SingleInstance force
~^s::
    IfWinActive, hotkeys.ahk - winconf - Visual Studio Code
    {
        Sleep, 200
        Reload
    }
    else IfWinActive, hotkeys-apps.ahk - winconf - Visual Studio Code
    {
        Sleep, 200
        Reload
    }
    else IfWinActive, load.ahk - winconf - Visual Studio Code
    {
        Sleep, 200
        Reload
    }
    ; Add more else IfWinActive conditions here for each additional file
return

+F12::
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
    DllCall("LockWorkStation")
    sleep, 1000
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
return

^F12::
    RestartExplorer()
Return
