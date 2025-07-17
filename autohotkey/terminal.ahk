#Requires AutoHotkey v2.0

primaryTerminalId := 0
SetWinEventHook(0x0003)

SetWinEventHook(eventMin, eventMax := 0, hmodWinEventProc := 0, idProcess := 0, idThread := 0, dwFlags := 0) {
    static WINEVENT_OUTOFCONTEXT := 0x0000
    return DllCall("SetWinEventHook", "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc, "Ptr",
        CallbackCreate(WinEventProc), "UInt", idProcess, "UInt", idThread, "UInt", WINEVENT_OUTOFCONTEXT)
}

WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global primaryTerminalId
    if (hwnd && WinExist("ahk_id " . hwnd) && WinGetProcessName("ahk_id " . hwnd) = "wezterm-gui.exe") {
        primaryTerminalId := hwnd
    }
}

#Enter::
{
    global primaryTerminalId
    if (primaryTerminalId && WinExist("ahk_id " . primaryTerminalId)) {
        if (WinActive("ahk_id " . primaryTerminalId)) {
            WinMinimize(primaryTerminalId)
            return
        }
        WinShow(primaryTerminalId)
        WinRestore(primaryTerminalId)
        WinActivate(primaryTerminalId)
        return
    }

    if WinExist("ahk_exe wezterm-gui.exe") {
        for hwnd in WinGetList("ahk_exe wezterm-gui.exe") {
            if (hwnd != WinGetID("A")) {
                WinShow(hwnd)
                WinRestore(hwnd)
                WinActivate(hwnd)
                primaryTerminalId := hwnd
                return
            }
        }
    }
    LaunchTerminal()
}

#+Enter:: LaunchTerminal()

LaunchTerminal() {
    global primaryTerminalId
    userDir := "C:\Users\" . EnvGet("username")
    paths := [
        "C:\Program Files\WezTerm\wezterm-gui.exe",
        "C:\Program Files (x86)\WezTerm\wezterm-gui.exe",
        userDir . "\AppData\Local\Microsoft\WindowsApps\wezterm-gui.exe"
    ]

    for path in paths {
        if FileExist(path) {
            existingWindows := WinGetList("ahk_exe wezterm-gui.exe")
            Run(path . " start -- wsl.exe -d Ubuntu --cd ~")

            startTime := A_TickCount
            while (A_TickCount - startTime < 3000) {
                currentWindows := WinGetList("ahk_exe wezterm-gui.exe")
                if (currentWindows.Length > existingWindows.Length) {
                    for hwnd in currentWindows {
                        if !existingWindows.Has(hwnd) {
                            primaryTerminalId := hwnd
                            WinActivate(hwnd)
                            return
                        }
                    }
                }
                Sleep(50)
            }
            return
        }
    }
}
