#Requires AutoHotkey v2.0

global targetWindows := Map()

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
    ToolTip("Window: " . winID . " bound to hotkey: " . SubStr(hotKey, StrLen(hotKey) - 1, 2))
    Sleep(1000)
    ToolTip("")
}

CycleWindowsWithinSameClass(Direction) {
    activeHwnd := WinExist("A")
    wClass := WinGetClass()
    exe := WinGetProcessName()

    DetectHiddenWindows(false)
    hWnds := WinGetList("ahk_exe " exe " ahk_class " wClass)

    currentIndex := 0
    for index, hWnd in hWnds {
        if (activeHwnd == hWnd) {
            currentIndex := index
            break
        }
    }

    targetIndex := currentIndex + Direction
    if (targetIndex < 1)
        targetIndex := hWnds.Length
    else if (targetIndex > hWnds.Length)
        targetIndex := 1

    WinActivate("ahk_id " hWnds[targetIndex])
}

CenterWindow(hwnd := WinExist("A")) {
    if !hwnd
        return

    WinGetPos &winX, &winY, &winW, &winH, hwnd

    winMidX := winX + winW // 2
    winMidY := winY + winH // 2

    monIdx := MonitorGetPrimary()
    monLeft := monTop := monW := monH := 0

    loop MonitorGetCount() {
        MonitorGet A_Index, &mL, &mT, &mR, &mB
        if (winMidX >= mL && winMidX < mR && winMidY >= mT && winMidY < mB) {
            monIdx := A_Index
            monLeft := mL
            monTop := mT
            monW := mR - mL
            monH := mB - mT
            break
        }
    }

    if !monW {
        MonitorGet monIdx, &monLeft, &monTop, &mR, &mB
        monW := mR - monLeft
        monH := mB - monTop
    }

    newX := monLeft + (monW - winW) // 2
    newY := monTop + (monH - winH) // 2
    WinMove newX, newY, , , hwnd
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
        if WinWait(windowID, , 10) {
            hwnd := WinExist(windowID)
            WinActivate("ahk_id " . hwnd)
        }
    }
}
