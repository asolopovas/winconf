#Requires AutoHotkey v2.0
SetKeyDelay(0, 50)
#Include "helpers/runasuser.ahk"
#Include "hotkeys-apps.ahk"
#Include "desktop-switcher/user_config.ahk"


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

global targetWindows := Map() ; A map to store window handles

GetTargetKey(val) {
   Return SubStr(val, StrLen(val), 1)
}

BindWindow(hotKey) {
    targetKey := GetTargetKey(hotKey)
    winID := WinGetID("A")
    targetWindows[targetKey] := winID
    ToolTip("Window: " . winID . " bound to hotkey: " . SubStr(hotKey, StrLen(hotKey)-1, 2))
    Sleep(1000)
    ToolTip("")
}

ActivateWindow(hotKey) {
    targetKey := GetTargetKey(hotKey)
    if (targetWindows.Has(targetKey)) {
        WinActivate targetWindows[targetKey]
    } else {
        ToolTip("No window bound!")
        Sleep(1000)
        ToolTip("")
    }
}

Loop 9 {
    currentKey := A_Index
    Hotkey "<^>!F" . currentKey, BindWindow
    Hotkey '!F' . currentKey, ActivateWindow
}

!j::
 {
    CycleWindowsWithinSameClass(-1)
 }
!k::
{
    CycleWindowsWithinSameClass(+1)
}

CycleWindowsWithinSameClass(Direction)
{
	; DetectHiddenWindows(false)
	activeWindow := WinExist("A")
	exe := WinGetProcessName()
	total := windowObjects.Length
    current := 0

	for win in windowObjects {
		if (activeWindow = win)
            current := A_Index
	}

    target := current + Direction

    if (target < 1) {
        target := total
    }

    if (target > total) {
        target := 1
    }

    if (WinGetClass(windowObjects[target]) = "Shell_TrayWnd") {
        target += Direction
    }

    if (target < 1) {
        target := total
    }

    if (target > total) {
        target := 1
    }

    if (WinExist(windowObjects[target])) {
        targetWindow  := windowObjects[target]
        WinActivate("ahk_id" targetWindow)
    }

}

CycleAllWindows(Direction)
{
	; DetectHiddenWindows(false)
	activeWindow := WinExist("A")
	exe := WinGetProcessName()
	total := windowObjects.Length
    current := 0

	for win in windowObjects {
		if (activeWindow = win)
            current := A_Index
	}

    target := current + Direction

    if (target < 1) {
        target := total
    }

    if (target > total) {
        target := 1
    }

    if (WinGetClass(windowObjects[target]) = "Shell_TrayWnd") {
        target += Direction
    }

    if (target < 1) {
        target := total
    }

    if (target > total) {
        target := 1
    }

    if (WinExist(windowObjects[target])) {
        targetWindow  := windowObjects[target]
        WinActivate("ahk_id" targetWindow)
    }

}

; ids := WinGetList(,, "Program Manager")
; for this_id in ids
; {
;     WinActivate this_id
;     this_class := WinGetClass(this_id)
;     this_title := WinGetTitle(this_id)
;     Result := MsgBox(
;     (
;         "Visiting All Windows
;         " A_Index " of " ids.Length "
;         ahk_id " this_id "
;         ahk_class " this_class "
;         " this_title "

;         Continue?"
;     ),, 4)
;     if (Result = "No")
;         break
; }
