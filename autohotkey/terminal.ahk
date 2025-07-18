#Requires AutoHotkey v2.0
#Include "debug.ahk"

currentToggleId := 0
previousToggleId := 0
currentPowershellId := 0
previousPowershellId := 0

#Enter:: ToggleTerminal("Ubuntu")
<^>!Enter:: ToggleTerminal("Powershell")

#+Enter:: LaunchTerminal('Ubuntu')
<^>!+Enter:: LaunchTerminal('Powershell')

SetTimer(UpdateTerminalTracking, 500)

UpdateTerminalTracking() {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    if (currentToggleId && !WinExist("ahk_id " . currentToggleId)) {
        DebugLog("TRACK", "Current Ubuntu terminal closed", currentToggleId, "-")
        currentToggleId := previousToggleId
        previousToggleId := 0

        if (currentToggleId) {
            DebugLog("TRACK", "Switched to previous Ubuntu terminal", currentToggleId, "-")
        }
    }

    if (previousToggleId && !WinExist("ahk_id " . previousToggleId)) {
        DebugLog("TRACK", "Previous Ubuntu terminal closed", previousToggleId, "-")
        previousToggleId := 0
    }

    if (currentPowershellId && !WinExist("ahk_id " . currentPowershellId)) {
        DebugLog("TRACK", "Current PowerShell terminal closed", currentPowershellId, "-")
        currentPowershellId := previousPowershellId
        previousPowershellId := 0

        if (currentPowershellId) {
            DebugLog("TRACK", "Switched to previous PowerShell terminal", currentPowershellId, "-")
        }
    }

    if (previousPowershellId && !WinExist("ahk_id " . previousPowershellId)) {
        DebugLog("TRACK", "Previous PowerShell terminal closed", previousPowershellId, "-")
        previousPowershellId := 0
    }
}

ToggleTerminal(terminalType := "Ubuntu") {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    if (terminalType == "Powershell") {
        DebugLog("TOGGLE", "PowerShell - Current: " . currentPowershellId . " Previous: " . previousPowershellId, "-", "-")

        if (currentPowershellId && WinExist("ahk_id " . currentPowershellId)) {
            minMax := WinGetMinMax("ahk_id " . currentPowershellId)
            isActive := WinActive("ahk_id " . currentPowershellId)

            DebugLog("TOGGLE", "PowerShell State - Active: " . isActive . " MinMax: " . minMax, currentPowershellId, "-")

            if (isActive) {
                DebugLog("TOGGLE_MINIMIZE", currentPowershellId)
                WinMinimize(currentPowershellId)
                return
            } else if (minMax = -1) {
                DebugLog("TOGGLE_RESTORE", currentPowershellId)
                WinRestore(currentPowershellId)
                WinActivate(currentPowershellId)
                return
            } else {
                DebugLog("TOGGLE_ACTIVATE", currentPowershellId)
                WinShow(currentPowershellId)
                WinActivate(currentPowershellId)
                return
            }
        }
    } else {
        DebugLog("TOGGLE", "Ubuntu - Current: " . currentToggleId . " Previous: " . previousToggleId, "-", "-")

        if (currentToggleId && WinExist("ahk_id " . currentToggleId)) {
            minMax := WinGetMinMax("ahk_id " . currentToggleId)
            isActive := WinActive("ahk_id " . currentToggleId)

            DebugLog("TOGGLE", "Ubuntu State - Active: " . isActive . " MinMax: " . minMax, currentToggleId, "-")

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
    }

    LaunchTerminal(terminalType)
}


LaunchTerminal(terminal := 'Ubuntu') {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId
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
                RunAsUser(path, " start -- wsl.exe -d Ubuntu --cd ~")
            }

            if (terminal == 'Powershell') {
                RunAsUser(path, " start -- powershell.exe")
            }

            Loop 60 {
                Sleep(50)
                for hwnd in WinGetList("ahk_exe wezterm-gui.exe") {
                    if !existingWindows.Has(hwnd) {
                        if (terminal == "Powershell") {
                            if (currentPowershellId) {
                                previousPowershellId := currentPowershellId
                            }
                            currentPowershellId := hwnd
                            DebugLog("LAUNCH", "New PowerShell terminal created", hwnd, "-")
                            DebugLog("LAUNCH", "PowerShell - Previous: " . previousPowershellId . " Current: " . currentPowershellId, "-", "-")
                        } else {
                            if (currentToggleId) {
                                previousToggleId := currentToggleId
                            }
                            currentToggleId := hwnd
                            DebugLog("LAUNCH", "New Ubuntu terminal created", hwnd, "-")
                            DebugLog("LAUNCH", "Ubuntu - Previous: " . previousToggleId . " Current: " . currentToggleId, "-", "-")
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
