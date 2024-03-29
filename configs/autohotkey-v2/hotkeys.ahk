#Include "helpers/runasuser.ahk"
#Include "hotkeys-apps.ahk"

RestartExplorer(delay:=-1) {
    If (A_OSVersion != "WIN_XP") {
        PID := WinGetPID("ahk_class Shell_TrayWnd")
        PostMessage(0x5B4, 0, 0, , "ahk_class Shell_TrayWnd")
        PostMessage(0x111, 518, 0, , "ahk_class Shell_TrayWnd")
    } Else {
        PID := WinGetPID("ahk_class Progman")
        PostMessage(0x012, 0, 0, , "ahk_class Progman")
        PostMessage(0x012, 0, 1, , "ahk_class Progman")
        PostMessage(0x012, 0, 0, , "ahk_class Shell_TrayWnd")
    }
    RunWait("taskkill /F /IM explorer.exe", , "Hide")
    Sleep(delay)
    If ((A_OSVersion != "WIN_XP") && A_IsAdmin) {
        hMod := DllCall("LoadLibrary", "Str", "wdc.dll", "Ptr")
        WdcRunAsIU := DllCall("GetProcAddress", "Ptr", hMod, "AStr", "WdcRunTaskAsInteractiveUser", "Ptr")
        DllCall(WdcRunAsIU, "WStr", "%windir%\explorer.exe", "Ptr", 0, "UInt", 9, "UInt")
        DllCall("FreeLibrary", "Ptr", hMod)
    } Else {
        ErrorLevel := "ERROR"
        Try ErrorLevel := Run(A_WinDir "\explorer.exe", A_WinDir "\system32", "", )
    }
}

#h::#Left
#j::#Down
#k::#Up
#l::#Right

LWin & .::AltTab
LWin & ,::ShiftAltTab

#f::
{
    MMX := WinGetMinMax("A")
    if (MMX = 0)
    {
        WinMaximize("A")
    }
    else if (MMX = 1)
    {
        WinRestore("A")
    }
}


#q::
    {
        Title := WinGetTitle("A")
        PostMessage(0x112, 0xF060, , , Title)
        return

        #SingleInstance force
    }

~^s::
    {
        if WinActive("hotkeys.ahk - winconf - Visual Studio Code")
        {
            Sleep(200)
            Reload()
        }
        else if WinActive("hotkeys-apps.ahk - winconf - Visual Studio Code")
        {
            Sleep(200)
            Reload()
        }
        else if WinActive("load.ahk - winconf - Visual Studio Code")
        {
            Sleep(200)
            Reload()
        }
        return
    }

; !F11::
;     {
;         RegWrite(0, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableLockWorkstation")
;         DllCall("LockWorkStation")
;         Sleep(1000)
;         RegWrite(1, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableLockWorkstation")
;         return
;     }

!+F11::
    {
        RestartExplorer()
        Return
    }
