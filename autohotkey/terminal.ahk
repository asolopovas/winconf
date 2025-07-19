#Requires AutoHotkey v2.0
#Include "debug.ahk"
#Include "runasuser.ahk"

currentToggleId := 0
previousToggleId := 0
currentPowershellId := 0
previousPowershellId := 0

#Enter:: ToggleTerminal("Ubuntu")
<^>!Enter:: ToggleTerminal("Powershell")

#+Enter:: LaunchTerminal('Ubuntu')
<^>!+Enter:: LaunchTerminal('Powershell')

#F12::
{
    ; Launch WezTerm as administrator
    windowID := "ahk_exe wezterm-gui.exe ahk_class Admin"
    if (WinExist(windowID)) {
        WinActivate(windowID)
    } else {
        ; Find WezTerm path
        weztermPath := ""
        possiblePaths := [
            "C:\\Program Files\\WezTerm\\wezterm-gui.exe",
            "C:\\Program Files (x86)\\WezTerm\\wezterm-gui.exe",
            "C:\\Users\\" . EnvGet("username") . "\\AppData\\Local\\Microsoft\\WindowsApps\\wezterm-gui.exe",
            "C:\\tools\\wezterm\\wezterm-gui.exe"
        ]

        for path in possiblePaths {
            if FileExist(path) {
                weztermPath := path
                break
            }
        }

        if (weztermPath != "") {
            ; Launch WezTerm as administrator with Admin class
            args := "start --class Admin"
            Run("*RunAs " . weztermPath . " " . args)
        }
    }
}

SetTimer(UpdateTerminalTracking, 500)

UpdateTerminalTracking() {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    if (currentToggleId && !WinExist("ahk_id " . currentToggleId)) {
        currentToggleId := previousToggleId
        previousToggleId := 0

    }

    if (previousToggleId && !WinExist("ahk_id " . previousToggleId)) {
        previousToggleId := 0
    }

    if (currentPowershellId && !WinExist("ahk_id " . currentPowershellId)) {
        currentPowershellId := previousPowershellId
        previousPowershellId := 0
    }

    if (previousPowershellId && !WinExist("ahk_id " . previousPowershellId)) {
        previousPowershellId := 0
    }
}

ToggleTerminal(terminalType := "Ubuntu") {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    if (terminalType == "Powershell") {

        if (currentPowershellId && WinExist("ahk_id " . currentPowershellId)) {
            minMax := WinGetMinMax("ahk_id " . currentPowershellId)
            isActive := WinActive("ahk_id " . currentPowershellId)

            if (isActive) {
                WinMinimize(currentPowershellId)
                return
            } else if (minMax = -1) {
                WinRestore(currentPowershellId)
                WinActivate(currentPowershellId)
                return
            } else {
                WinShow(currentPowershellId)
                WinActivate(currentPowershellId)
                return
            }
        }
    } else {

        if (currentToggleId && WinExist("ahk_id " . currentToggleId)) {
            minMax := WinGetMinMax("ahk_id " . currentToggleId)
            isActive := WinActive("ahk_id " . currentToggleId)

            if (isActive) {
                WinMinimize(currentToggleId)
                return
            } else if (minMax = -1) {
                WinRestore(currentToggleId)
                WinActivate(currentToggleId)
                return
            } else {
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

    existingWindows := Map()
    for hwnd in WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS") {
        existingWindows[hwnd] := true
    }

    terminal_path := "C:\Users\asolo\AppData\Local\Microsoft\WindowsApps\wt.exe"

    if (terminal == "Ubuntu") {
        RunAsUser(terminal_path, "new-tab -p Ubuntu")
    }

    if (terminal == 'Powershell') {
        RunAsUser(terminal_path, "new-tab -p PowerShell")
    }

    loop 60 {
        Sleep(50)
        for hwnd in WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS") {
            if !existingWindows.Has(hwnd) {
                if (terminal == "Powershell") {
                    if (currentPowershellId) {
                        previousPowershellId := currentPowershellId
                    }
                    currentPowershellId := hwnd
                } else {
                    if (currentToggleId) {
                        previousToggleId := currentToggleId
                    }
                    currentToggleId := hwnd
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
}
