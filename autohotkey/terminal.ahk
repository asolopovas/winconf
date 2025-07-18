#Requires AutoHotkey v2.0
#Include "debug.ahk"

currentToggleId := 0
previousToggleId := 0

#Enter:: ToggleTerminal("Ubuntu")
<^>!Enter:: ToggleTerminal("Powershell")

#+Enter:: LaunchTerminal('Ubuntu')
<^>!+Enter:: LaunchTerminal('Powershell')

SetTimer(UpdateTerminalTracking, 500)

UpdateTerminalTracking() {
    global currentToggleId, previousToggleId

    if (currentToggleId && !WinExist("ahk_id " . currentToggleId)) {
        DebugLog("TRACK", "Current terminal closed", currentToggleId, "-")
        currentToggleId := previousToggleId
        previousToggleId := 0

        if (currentToggleId) {
            DebugLog("TRACK", "Switched to previous terminal", currentToggleId, "-")
        }
    }

    if (previousToggleId && !WinExist("ahk_id " . previousToggleId)) {
        DebugLog("TRACK", "Previous terminal closed", previousToggleId, "-")
        previousToggleId := 0
    }
}

ToggleTerminal(terminalType := "Ubuntu") {
    global currentToggleId, previousToggleId

    DebugLog("TOGGLE", "Current: " . currentToggleId . " Previous: " . previousToggleId, "-", "-")

    if (currentToggleId && WinExist("ahk_id " . currentToggleId)) {
        minMax := WinGetMinMax("ahk_id " . currentToggleId)
        isActive := WinActive("ahk_id " . currentToggleId)

        DebugLog("TOGGLE", "State - Active: " . isActive . " MinMax: " . minMax, currentToggleId, "-")

        if (isActive) {
            DebugLog("TOGGLE_MINIMIZE", currentToggleId)
            WinMinimize(currentToggleId)
            return
        } else if (minMax = -1) {
            DebugLog("TOGGLE_RESTORE", currentToggleId)
            WinRestore(currentToggleId)
            WinActivate(currentToggleId)
            return
        } else {
            DebugLog("TOGGLE_ACTIVATE", currentToggleId)
            WinShow(currentToggleId)
            WinActivate(currentToggleId)
            return
        }
    }

    if (WinExist("ahk_exe wezterm-gui.exe")) {
        for hwnd in WinGetList("ahk_exe wezterm-gui.exe") {
            WinShow(hwnd)
            WinRestore(hwnd)
            WinActivate(hwnd)
            currentToggleId := hwnd
            DebugLog("TOGGLE", "Found existing terminal", hwnd, "-")
            return
        }
    }

    LaunchTerminal(terminalType)
}


LaunchTerminal(terminal := 'Ubuntu') {
    global currentToggleId, previousToggleId
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
                        if (currentToggleId) {
                            previousToggleId := currentToggleId
                        }
                        currentToggleId := hwnd

                        DebugLog("LAUNCH", "New terminal created", hwnd, "-")
                        DebugLog("LAUNCH", "Previous: " . previousToggleId . " Current: " . currentToggleId, "-", "-")

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
