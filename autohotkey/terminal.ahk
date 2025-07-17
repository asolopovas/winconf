#Requires AutoHotkey v2.0

ubuntuTerminalId := 0
powershellTerminalId := 0
SetWinEventHook(0x0003)

SetWinEventHook(
    eventMin,
    eventMax := 0,
    hmodWinEventProc := 0,
    idProcess := 0,
    idThread := 0,
    dwFlags := 0
) {
    static WINEVENT_OUTOFCONTEXT := 0x0000
    return DllCall("SetWinEventHook", "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc, "Ptr",
        CallbackCreate(WinEventProc), "UInt", idProcess, "UInt", idThread, "UInt", WINEVENT_OUTOFCONTEXT)
}

WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global ubuntuTerminalId, powershellTerminalId
    if (hwnd && WinExist("ahk_id " . hwnd) && WinGetProcessName("ahk_id " . hwnd) = "wezterm-gui.exe") {
        try {
            title := WinGetTitle("ahk_id " . hwnd)
            if (InStr(title, "~") || InStr(title, "Ubuntu")) {
                if (!ubuntuTerminalId) {
                    ubuntuTerminalId := hwnd
                }
            } else if (InStr(title, "powershell.exe") || InStr(title, "PowerShell")) {
                if (!powershellTerminalId) {
                    powershellTerminalId := hwnd
                }
            }
        }
    }
}

ToggleTerminal(terminalType) {
    global ubuntuTerminalId, powershellTerminalId

    terminalId := (terminalType == "Ubuntu") ? ubuntuTerminalId : powershellTerminalId

    if (terminalId && WinExist("ahk_id " . terminalId)) {
        if (WinActive("ahk_id " . terminalId)) {
            WinMinimize(terminalId)
            return
        }
        WinShow(terminalId)
        WinRestore(terminalId)
        WinActivate(terminalId)
        return
    }

    if (terminalType == "Ubuntu" && WinExist("ahk_exe wezterm-gui.exe")) {
        for hwnd in WinGetList("ahk_exe wezterm-gui.exe") {
            if (hwnd != WinGetID("A")) {
                try {
                    title := WinGetTitle("ahk_id " . hwnd)
                    if (InStr(title, "wsl") || InStr(title, "Ubuntu") || InStr(title, "bash")) {
                        WinShow(hwnd)
                        WinRestore(hwnd)
                        WinActivate(hwnd)
                        ubuntuTerminalId := hwnd
                        return
                    }
                }
            }
        }
    }

    LaunchTerminal(terminalType == "Ubuntu" ? "Ubuntu" : "Powershell")
}

#Enter:: ToggleTerminal("Ubuntu")
<^>!Enter:: ToggleTerminal("Powershell")

#+Enter:: LaunchTerminal('Ubuntu')
<^>!+Enter::LaunchTerminal('Powershell')

LaunchTerminal(terminal := 'Ubuntu') {
    global ubuntuTerminalId, powershellTerminalId
    userDir := "C:\Users\" . EnvGet("username")
    paths := [
        "C:\Program Files\WezTerm\wezterm-gui.exe",
        "C:\Program Files (x86)\WezTerm\wezterm-gui.exe",
        userDir . "\AppData\Local\Microsoft\WindowsApps\wezterm-gui.exe"
    ]

    for path in paths {
        if FileExist(path) {
            existingWindows := WinGetList("ahk_exe wezterm-gui.exe")
            if (terminal == "Ubuntu") {
                Run(path . " start -- wsl.exe -d Ubuntu --cd ~")
            }

            if (terminal == 'Powershell') {
                RunAsUser(path, "start -- powershell.exe")
            }

            startTime := A_TickCount
            while (A_TickCount - startTime < 3000) {
                currentWindows := WinGetList("ahk_exe wezterm-gui.exe")
                if (currentWindows.Length > existingWindows.Length) {
                    for hwnd in currentWindows {
                        if !existingWindows.Has(hwnd) {
                            if (terminal == "Ubuntu") {
                                ubuntuTerminalId := hwnd
                            } else if (terminal == 'Powershell') {
                                powershellTerminalId := hwnd
                            }
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
