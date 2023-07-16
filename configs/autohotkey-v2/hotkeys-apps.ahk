RunOrActivate(windowID, exePath, args, alwaysNewInstance := false) {
    if (!alwaysNewInstance && WinExist(windowID)) {
        if WinActive(windowID) {
            WinMinimize("ahk_id " . WinExist(windowID))
        } else {
            WinActivate(windowID)
        }
    } else {
        RunAsUser(exePath, args)
        WinWait(windowID)
        WinActivate(windowID)
    }
}

RunOrActivateTerminal(windowTitle, alwaysNewInstance := false) {
    username := EnvGet("username")
    terminalPath := "C:\\Users\\" . username . "\\AppData\\Local\\Microsoft\\WindowsApps\\wt.exe"
    args := "-w " . windowTitle . " nt -p " . windowTitle . " --suppressApplicationTitle"
    windowID := windowTitle " ahk_class CASCADIA_HOSTING_WINDOW_CLASS"

    RunOrActivate(windowID, terminalPath, args, alwaysNewInstance)
}

#F12::
    {
        RunOrActivateTerminal("PowerShell")
    }

#+F12::
    {
        RunOrActivateTerminal("Admin", true)
    }

#Enter::
    {
        RunOrActivateTerminal("Ubuntu")
    }

#+Enter::
    {
        RunOrActivateTerminal("Ubuntu", true)
    }

#c::
    {
        windowID := "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"
        exePath := "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
        RunOrActivate(windowId, exePath, "")
    }

#m::
    {
        windowID := "ahk_class Chrome_WidgetWin_0 ahk_exe Spotify.exe"
        exePath := A_AppData . "\\Spotify\\Spotify.exe"

        if (!WinExist(windowID)) {
            RunAsUser(exePath)
            WinWait(windowID)
        } else if (WinActive(windowID)) {
            PostMessage(0x112, 0xF060, , , "ahk_id " . WinActive("A"))
        }

    }
