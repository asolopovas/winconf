#Requires AutoHotkey v2.0
#Include "debug.ahk"
#Include "runasuser.ahk"

currentToggleId := 0
previousToggleId := 0
currentPowershellId := 0
previousPowershellId := 0
lastActivatedTerminalId := 0
lastActivatedTerminalAt := 0

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
        RunTerminal("new-tab -p PowerShell")
    }
}

TerminalPath() => EnvGet("LOCALAPPDATA") . "\Microsoft\WindowsApps\wt.exe"

RunTerminal(arguments) {
    terminal_path := TerminalPath()

    try {
        Run('"' . terminal_path . '" ' . arguments)
        return true
    } catch {
        return false
    }
}

TrackTerminalWindow(hwnd, terminal) {
    global currentToggleId, previousToggleId, currentPowershellId, previousPowershellId

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
}

TerminalMatchesProfile(hwnd, terminal) {
    title := ""
    try title := WinGetTitle("ahk_id " . hwnd)
    isPowershell := RegExMatch(title, "i)PowerShell|pwsh")
    return terminal == "Powershell" ? isPowershell : !isPowershell
}

FindTerminalWindow(terminal) {
    global currentToggleId, currentPowershellId

    targetId := terminal == "Powershell" ? currentPowershellId : currentToggleId
    if (targetId && TerminalWindowExists(targetId)) {
        return targetId
    }

    for hwnd in WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS") {
        if TerminalMatchesProfile(hwnd, terminal) {
            TrackTerminalWindow(hwnd, terminal)
            return hwnd
        }
    }

    return 0
}

WaitForNewTerminalWindow(existingWindows, terminal, timeoutMs := 3000) {
    deadline := A_TickCount + timeoutMs
    while (A_TickCount < deadline) {
        Sleep(50)
        for hwnd in WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS") {
            if !existingWindows.Has(hwnd) {
                ActivateTerminalWindow(hwnd)
                TrackTerminalWindow(hwnd, terminal)
                return hwnd
            }
        }
    }
    return 0
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
    return true
}

ToggleTerminal(terminalType := "Ubuntu") {
    global lastActivatedTerminalId, lastActivatedTerminalAt
    targetId := FindTerminalWindow(terminalType)

    if (targetId) {
        windowID := "ahk_id " . targetId
        justActivated := targetId == lastActivatedTerminalId && A_TickCount - lastActivatedTerminalAt < 700

        if (WinActive(windowID) || justActivated) {
            lastActivatedTerminalId := 0
            WinMinimize(windowID)
            KeyWait("Enter")
            return
        }

        lastActivatedTerminalId := targetId
        lastActivatedTerminalAt := A_TickCount
        ActivateTerminalWindow(targetId)
        KeyWait("Enter")
        return
    }

    LaunchTerminal(terminalType)
    KeyWait("Enter")
}

OpenNewTab(terminal := 'Ubuntu') {
    if (terminal == "Ubuntu") {
        profile := "Ubuntu"
    } else {
        profile := "PowerShell"
    }

    targetId := FindTerminalWindow(terminal)
    if (targetId) {
        WinActivate("ahk_id " . targetId)
        WinWaitActive("ahk_id " . targetId, , 2)
        RunTerminal("--window 0 new-tab -p " . profile)
    } else {
        LaunchTerminal(terminal)
    }
}

LaunchTerminal(terminal := 'Ubuntu') {
    global lastActivatedTerminalId, lastActivatedTerminalAt
    existingWindows := Map()
    for hwnd in WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS") {
        existingWindows[hwnd] := true
    }

    if (terminal == "Ubuntu") {
        arguments := "-w new new-tab -p Ubuntu"
    }

    if (terminal == 'Powershell') {
        arguments := "-w new new-tab -p PowerShell"
    }

    RunTerminal(arguments)
    hwnd := WaitForNewTerminalWindow(existingWindows, terminal, 5000)
    if (hwnd) {
        lastActivatedTerminalId := hwnd
        lastActivatedTerminalAt := A_TickCount
    }
}
