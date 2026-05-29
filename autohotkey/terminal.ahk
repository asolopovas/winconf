#Requires AutoHotkey v2.0
#Include "debug.ahk"
#Include "runasuser.ahk"

currentToggleId := 0
previousToggleId := 0
currentPowershellId := 0
previousPowershellId := 0

if (!IsSet(REGISTER_TERMINAL_HOTKEYS) || REGISTER_TERMINAL_HOTKEYS) {
    Hotkey("#Enter", (*) => ToggleTerminal("Ubuntu"))
    Hotkey("<^>!Enter", (*) => ToggleTerminal("Powershell"))
    Hotkey("#+Enter", (*) => OpenNewTab("Ubuntu"))
    Hotkey("<^>!+Enter", (*) => OpenNewTab("Powershell"))
    Hotkey("#F12", (*) => ActivateAnyTerminal())
}

ActivateAnyTerminal() {
    windowID := "ahk_class CASCADIA_HOSTING_WINDOW_CLASS"
    if (WinExist(windowID)) {
        WinActivate(windowID)
    } else {
        terminal_path := "C:\Users\asolo\AppData\Local\Microsoft\WindowsApps\wt.exe"

        Run(terminal_path . " new-tab -p PowerShell")
    }
}

SetTimer(UpdateTerminalTracking, 500)

UpdateTerminalTracking() {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    if (currentToggleId && !TerminalWindowExists(currentToggleId)) {
        currentToggleId := previousToggleId
        previousToggleId := 0
    }

    if (previousToggleId && !TerminalWindowExists(previousToggleId)) {
        previousToggleId := 0
    }

    if (currentPowershellId && !TerminalWindowExists(currentPowershellId)) {
        currentPowershellId := previousPowershellId
        previousPowershellId := 0
    }

    if (previousPowershellId && !TerminalWindowExists(previousPowershellId)) {
        previousPowershellId := 0
    }
}

TerminalWindowExists(hwnd) {
    if (!hwnd) {
        return false
    }

    oldDetectHiddenWindows := DetectHiddenWindows(true)
    exists := WinExist("ahk_id " . hwnd)
    DetectHiddenWindows(oldDetectHiddenWindows)
    return exists
}

ActivateTerminalWindow(hwnd) {
    if (!TerminalWindowExists(hwnd)) {
        return false
    }

    windowID := "ahk_id " . hwnd

    if (WinGetMinMax(windowID) = -1) {
        WinRestore(windowID)
    }

    WinShow(windowID)
    WinActivate(windowID)
    WinWaitActive(windowID, , 2)
    return WinActive(windowID)
}

ToggleTerminal(terminalType := "Ubuntu") {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    if (terminalType == "Powershell") {

        if (currentPowershellId && TerminalWindowExists(currentPowershellId)) {
            windowID := "ahk_id " . currentPowershellId

            if (WinActive(windowID)) {
                WinMinimize(windowID)
                return
            }

            ActivateTerminalWindow(currentPowershellId)
            return
        }
    } else {

        if (currentToggleId && TerminalWindowExists(currentToggleId)) {
            windowID := "ahk_id " . currentToggleId

            if (WinActive(windowID)) {
                WinMinimize(windowID)
                return
            }

            ActivateTerminalWindow(currentToggleId)
            return
        }
    }

    LaunchTerminal(terminalType)
}

OpenNewTab(terminal := 'Ubuntu') {
    global currentToggleId, currentPowershellId

    terminal_path := "C:\Users\asolo\AppData\Local\Microsoft\WindowsApps\wt.exe"

    if (terminal == "Ubuntu") {
        targetId := currentToggleId
        profile := "Ubuntu"
    } else {
        targetId := currentPowershellId
        profile := "PowerShell"
    }

    if (targetId && WinExist("ahk_id " . targetId)) {
        WinActivate("ahk_id " . targetId)
        WinWaitActive("ahk_id " . targetId, , 2)
        RunAsUser(terminal_path, "--window 0 new-tab -p " . profile)
    } else {
        LaunchTerminal(terminal)
    }
}

LaunchTerminal(terminal := 'Ubuntu') {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

    existingWindows := Map()
    for hwnd in WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS") {
        existingWindows[hwnd] := true
    }

    terminal_path := "C:\Users\asolo\AppData\Local\Microsoft\WindowsApps\wt.exe"

    if (terminal == "Ubuntu") {
        RunAsUser(terminal_path, "-w new new-tab -p Ubuntu")
    }

    if (terminal == 'Powershell') {
        RunAsUser(terminal_path, "-w new new-tab -p PowerShell")
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
