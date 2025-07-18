#Requires AutoHotkey v2.0

ubuntuTerminalId := 0
powershellTerminalId := 0

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
<^>!+Enter:: LaunchTerminal('Powershell')

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
            existingWindows := Map()
            for hwnd in WinGetList("ahk_exe wezterm-gui.exe") {
                existingWindows[hwnd] := true
            }
            
            if (terminal == "Ubuntu") {
                Run(path . " start -- wsl.exe -d Ubuntu --cd ~")
            }

            if (terminal == 'Powershell') {
                Run(path . " start -- powershell.exe")
            }

            Loop 60 {
                Sleep(50)
                for hwnd in WinGetList("ahk_exe wezterm-gui.exe") {
                    if !existingWindows.Has(hwnd) {
                        if (terminal == "Ubuntu") {
                            ubuntuTerminalId := hwnd
                        } else if (terminal == 'Powershell') {
                            powershellTerminalId := hwnd
                        }
                        
                        WinActivate("ahk_id " . hwnd)
                        WinWaitActive("ahk_id " . hwnd, , 2)
                        if WinActive("ahk_id " . hwnd) {
                            return
                        }
                        
                        WinShow("ahk_id " . hwnd)
                        WinRestore("ahk_id " . hwnd) 
                        WinActivate("ahk_id " . hwnd)
                        return
                    }
                }
            }
            return
        }
    }
}
