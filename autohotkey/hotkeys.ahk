#Include "%A_ScriptDir%\autohotkey\desktop-switcher\init.ahk"

; Desktop Switcher Hotkeys
#+1:: MoveCurrentWindowToDesktop(0)
#+2:: MoveCurrentWindowToDesktop(1)
#+3:: MoveCurrentWindowToDesktop(2)
#+4:: MoveCurrentWindowToDesktop(3)
#+5:: MoveCurrentWindowToDesktop(4)
#+6:: MoveCurrentWindowToDesktop(5)
#+7:: MoveCurrentWindowToDesktop(6)
#+8:: MoveCurrentWindowToDesktop(7)
#+9:: MoveCurrentWindowToDesktop(8)

#1:: MoveOrGotoDesktopNumber(0)
#2:: MoveOrGotoDesktopNumber(1)
#3:: MoveOrGotoDesktopNumber(2)
#4:: MoveOrGotoDesktopNumber(3)
#5:: MoveOrGotoDesktopNumber(4)
#6:: MoveOrGotoDesktopNumber(5)
#7:: MoveOrGotoDesktopNumber(6)
#8:: MoveOrGotoDesktopNumber(7)
#9:: MoveOrGotoDesktopNumber(8)

; Special Keys: https://autohotkey.com/docs/Hotkeys.htm
; ! = alt
; + = shift
; ^ = ctrl
; # = win

#h::#Left
#j::#Down
#k::#Up
#l::#Right

LWin & .::AltTab
LWin & ,::ShiftAltTab


#c::
{
    defaultBrowserPath := GetDefaultBrowserPath()
    if !defaultBrowserPath {
        ; Fallback to common browsers
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
                defaultBrowserPath := browserPath
                break
            }
        }
    }

    if defaultBrowserPath {
        pathParts := StrSplit(defaultBrowserPath, "\")
        if pathParts.Length > 0 {
            exeName := pathParts[pathParts.Length]
            windowId := "ahk_exe " . exeName
            RunOrActivate(windowId, defaultBrowserPath, "")
        }
    } else {
        MsgBox("No browser found")
    }
}

#b::
{
    commonFirefoxPaths := [
        "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
        "C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe",
        "C:\\Users\\" . A_UserName . "\\AppData\\Local\\Mozilla Firefox\\firefox.exe"
    ]

    firefoxPath := ""
    for browserPath in commonFirefoxPaths {
        if FileExist(browserPath) {
            firefoxPath := browserPath
            break
        }
    }

    if firefoxPath {
        windowId := "ahk_exe firefox.exe"
        RunOrActivate(windowId, firefoxPath, "")
    } else {
        MsgBox("Firefox not found")
    }
}

#m::
{
    windowID := "ahk_class TAIMPMainForm ahk_exe AIMP.exe"
    exePath := "C:\\Program Files\\AIMP\\AIMP.exe"
    RunOrActivate(windowID, exePath, "")
}

#x::
{
    windowID := "ahk_class dopus.lister ahk_exe dopus.exe"
    exePath := "C:\\Program Files\\GPSoftware\\Directory Opus\\dopus.exe"
    homeDir := EnvGet("USERPROFILE")
    RunOrActivate(windowID, exePath, '"' . homeDir . '"')
}

#+x::
{
    windowID := "ahk_class dopus.lister ahk_exe dopus.exe"
    exePath := "C:\\Program Files\\GPSoftware\\Directory Opus\\dopus.exe"
    homeDir := EnvGet("USERPROFILE")
    RunOrActivate(windowID, exePath, '"' . homeDir . '"', true)
}

#f::
{
    MMX := WinGetMinMax("A")
    if (MMX == 0) {
        WinMaximize("A")
    }
    else if (MMX == 1) {
        WinRestore("A")
    }
}

#q::
{
    try {
        if WinExist("A") {
            Title := WinGetTitle("A")
            PostMessage(0x112, 0xF060, , , Title)
        }
    }

    #SingleInstance force
}

~^s::
{
    if WinActive("hotkeys.ahk - winconf - Visual Studio Code") {
        Sleep(200)
        Reload()
    }
    else if WinActive("hotkeys-desktop-switcher.ahk - winconf - Visual Studio Code") {
        Sleep(200)
        Reload()
    }
    else if WinActive("load.ahk - winconf - Visual Studio Code") {
        Sleep(200)
        Reload()
    }
}

!+F11::
{
    RestartExplorer()
}

!.::
{
    CycleWindowsWithinSameClass(-1)
}
!,::
{
    CycleWindowsWithinSameClass(+1)
}

F7::
{
    windowID := "ahk_class TAIMPMainForm ahk_exe AIMP.exe"
    exePath := "C:\\Program Files\\AIMP\\AIMP.exe"
    RunOrActivate(windowID, exePath, "")

    WinWaitActive(windowID, , 2)

    Send("!{Del}")
    Send("{Enter}")
    Sleep(1000)
    Send("#m")
}

^+F11:: {
    Send("{F2}")
    Sleep(100)
    Send("{Right}")
    Sleep(50)
    SendText("->toArray()")
    Sleep(100)
    Send("{Enter}")
}

; Win+Ctrl+S - Show terminal status
#^s::
{
    KeyLogger(A_ThisHotkey)
    currentWin := WinGetID("A")
    currentProcessName := WinGetProcessName("A")
    count := WinGetCount("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")

    DebugLog("STATUS", currentWin, currentProcessName, count)

    if (count > 0) {
        termWindows := WinGetList("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")
        windowList := ""
        detailedList := ""
        for hwnd in termWindows {
            minMax := WinGetMinMax("ahk_id " . hwnd)
            WinGetPos(&x, &y, &width, &height, "ahk_id " . hwnd)
            windowList .= "ahk_id:" . hwnd . " "
            detailedList .= "ahk_id:" . hwnd . " MinMax:" . minMax . " Pos:" . x . "," . y . " Size:" . width . "x" .
                height . "`n"
        }
        DebugLog("STATUS_WINDOWS", windowList)
        DebugLog("STATUS_DETAILED", detailedList)
        MsgBox("Terminal windows: " . count . "`n" . detailedList, "Status", "T5")
    } else {
        MsgBox("No terminal windows found", "Status", "T2")
    }
}


F9:: ; Win + F9
{
    ahkId := GetActiveWindowID()

    A_Clipboard := ahkId
    MsgBox ahkId "`n`n(Copied to clipboard)"
}

#F9:: ; Win + F9
{
    result := InputBox("Enter ahk_id (e.g.,ahk_id 0x123456):", "Activate Window", "w300")

    if result.Result != "OK" || result.Value = "" {
        MsgBox "Canceled or no input provided."
        return
    }

    hwndInput := result.Value

    try
    {
        CenterWindow(hwndInput)
        WinActivate(hwndInput)
        if WinActive(hwndInput)
            MsgBox "Activated window with " hwndInput
        else
            MsgBox "Failed to activate window. The ID might be incorrect or the window is hidden."
    }
    catch {
        MsgBox "Error: Could not activate window with " hwndInput
    }
}


