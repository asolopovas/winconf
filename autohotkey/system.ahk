#Requires AutoHotkey v2.0

RestartExplorer(delay := -1) {
    if (A_OSVersion != "WIN_XP") {
        PID := WinGetPID("ahk_class Shell_TrayWnd")
        PostMessage(0x5B4, 0, 0, , "ahk_class Shell_TrayWnd")
        PostMessage(0x111, 518, 0, , "ahk_class Shell_TrayWnd")
    } else {
        PID := WinGetPID("ahk_class Progman")
        PostMessage(0x012, 0, 0, , "ahk_class Progman")
        PostMessage(0x012, 0, 1, , "ahk_class Progman")
        PostMessage(0x012, 0, 0, , "ahk_class Shell_TrayWnd")
    }
    RunWait("taskkill /F /IM explorer.exe", , "Hide")
    Sleep(delay)
    if ((A_OSVersion != "WIN_XP") && A_IsAdmin) {
        hMod := DllCall("LoadLibrary", "Str", "wdc.dll", "Ptr")
        WdcRunAsIU := DllCall("GetProcAddress", "Ptr", hMod, "AStr", "WdcRunTaskAsInteractiveUser", "Ptr")
        DllCall(WdcRunAsIU, "WStr", "%windir%\\explorer.exe", "Ptr", 0, "UInt", 9, "UInt")
        DllCall("FreeLibrary", "Ptr", hMod)
    } else {
        try {
            Run(A_WinDir "\\explorer.exe", A_WinDir "\\system32", "")
        }
    }
}

ToggleDefender() {
    static defenderOff := false
    if defenderOff {
        action := "$false"
        state := "ON"
    } else {
        action := "$true"
        state := "OFF"
    }
    defenderOff := !defenderOff
    TrayTip("Defender " . state, "Real-time protection is being turned " . state, defenderOff ? "2" : "1")
    cmd := 'powershell -Command "Start-Process powershell -ArgumentList '
        . "'-Command Set-MpPreference -DisableRealtimeMonitoring " . action . "' "
        . '-Verb RunAs -WindowStyle Hidden"'
    try {
        Run(cmd, , "Hide")
    } catch as err {
        defenderOff := !defenderOff
        TrayTip("Defender Toggle Failed", "Error: " . err.Message, "3")
    }
}

GetDefaultBrowserPath() {
    ; Direct fallback to installed browsers
    commonBrowsers := [
        "C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe",
        "C:\\Program Files (x86)\\BraveSoftware\\Brave-Browser\\Application\\brave.exe", 
        "C:\\Users\\" . A_UserName . "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\Application\\brave.exe",
        "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
        "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
        "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe"
    ]
    
    for browserPath in commonBrowsers {
        if FileExist(browserPath) {
            return browserPath
        }
    }
    
    return ""
}
