#Requires AutoHotkey v2.0
SetKeyDelay(0, 50)
#Include "helpers/runasuser.ahk"

; Special Keys: https://autohotkey.com/docs/Hotkeys.htm
; ! = alt
; + = shift
; ^ = ctrl
; # = win

global targetWindows := Map() ; A map to store window handles
Loop 9 {
    currentKey := A_Index
    Hotkey "<^>!F" . currentKey, BindWindow
    Hotkey '+F' . currentKey, ActivateWindow
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

BindWindow(hotKey) {
    targetKey := GetTargetKey(hotKey)
    winID := WinGetID("A")
    targetWindows[targetKey] := winID
    ToolTip("Window: " . winID . " bound to hotkey: " . SubStr(hotKey, StrLen(hotKey)-1, 2))
    Sleep(1000)
    ToolTip("")
}
CycleWindowsWithinSameClass(Direction)
{
    a := WinExist("A")
    wClass := WinGetClass()
    exe := WinGetProcessName()
    DetectHiddenWindows(false)
    hWnds := WinGetList("ahk_exe " exe " ahk_class " wClass)
    total := hWnds.Length
    key := 0
    for index, hWnd in hWnds {
        if (a = hWnd) {
            key := index
            break
        }
    }
    if (key = 0) {
        key := total
    }
    target := key + Direction
    if (target < 1) {
        target := total
    }
    if (target > total) {
        target := 1
    }
    if (WinExist("ahk_id " hWnds[target])) {
        WinActivate("ahk_id " hWnds[target])
    }
}

CycleWindows(Direction)
{
	DetectHiddenWindows(false)
    global windowObjects := WinGetList(,,"Program Manager")
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

GetDefaultBrowserPath() {
    try {
        ; Check the registry key for the current user
        browserRegPath := "HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice"
        browserProgId := RegRead(browserRegPath, "ProgId", "ChromeHTML")

        if !browserProgId {
            ; If not found, check the registry key for all users
            browserRegPath := "HKEY_CLASSES_ROOT\HTTP\shell\open\command"
            browserCmd := RegRead(browserRegPath)
        } else {
            ; If found, get the executable path associated with the ProgId
            browserRegPath := "HKEY_CLASSES_ROOT\" browserProgId "\shell\open\command"
            browserCmd := RegRead(browserRegPath)
        }
        ; Find the first and last double quote position
        startPos := InStr(browserCmd, '"')
        endPos := InStr(browserCmd, '"', 0, startPos + 1)

        ; Extract the executable path
        exePath := SubStr(browserCmd, startPos + 1, endPos - startPos - 1)
        return exePath

    } catch {
        ; If any error occurs, return a blank string
        return MsgBox("Error establishing default browser path.")
    }
}

GetTargetKey(val) {
   Return SubStr(val, StrLen(val), 1)
}

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

RunOrActivate(windowID, exePath, args, alwaysNewInstance := false) {
    if (!alwaysNewInstance && WinExist(windowID)) {
        if WinActive(windowID) {
            WinMinimize("ahk_id " . WinExist(windowID))
        } else {
            WinActivate(windowID)
        }
    } else {
        RunAsUser(exePath, args)
        WinWait(windowID)
        WinActivate(windowID)
    }
}

RunOrActivateTerminal(windowTitle, alwaysNewInstance := false) {
    username := EnvGet("username")
    terminalPath := "C:\\Users\\" . username . "\\AppData\\Local\\Microsoft\\WindowsApps\\wt.exe"
    args := "-w " . windowTitle . " nt -p " . windowTitle . " --suppressApplicationTitle"
    windowID := windowTitle " ahk_class CASCADIA_HOSTING_WINDOW_CLASS"

    RunOrActivate(windowID, terminalPath, args, alwaysNewInstance)
}


#Include "./fast-scroll.ahk"
#Include "../../hotkeys.ahk"
