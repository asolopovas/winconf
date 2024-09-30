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

<^>!Enter::
    {
        RunOrActivateTerminal("PowerShell")
    }

<^>!+Enter::
    {
        RunOrActivateTerminal("PowerShell", true)
    }

#F12::
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
        defaultBrowserPath := GetDefaultBrowserPath()
        exeName := StrSplit(defaultBrowserPath, "\").Pop()

        windowID := "ahk_class Chrome_WidgetWin_1 ahk_exe" . exeName
        RunOrActivate(windowId, defaultBrowserPath, "")
    }


#m::
    {
        windowID := "ahk_exe Spotify.exe"
        exePath := A_AppData . "\\Spotify\\Spotify.exe"

        if (!WinExist(windowID)) {
            RunAsUser(exePath)
            WinWait(windowID)
        } else {
            if (WinActive(windowID)) {
                PostMessage(0x112, 0xF060, , , "ahk_id " . WinActive("A"))
            } else {
                WinActivate
            }
        }

    }

; AutoHotkey v2 script to find the default web browser's executable path


GetDefaultBrowserPath() {
    try {
        ; Check the registry key for the current user
        browserRegPath := "HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice"
        browserProgId := RegRead(browserRegPath, "ProgId", "ChromeHTML")

        if !browserProgId {
            ; If not found, check the registry key for all users
            browserRegPath := "HKEY_CLASSES_ROOT\HTTP\shell\open\command"
            browserCmd := RegRead(browserRegPath)
        } else {
            ; If found, get the executable path associated with the ProgId
            browserRegPath := "HKEY_CLASSES_ROOT\" browserProgId "\shell\open\command"
            browserCmd := RegRead(browserRegPath)
        }
        ; Find the first and last double quote position
        startPos := InStr(browserCmd, '"')
        endPos := InStr(browserCmd, '"', 0, startPos + 1)

        ; Extract the executable path
        exePath := SubStr(browserCmd, startPos + 1, endPos - startPos - 1)
        return exePath

    } catch {
        ; If any error occurs, return a blank string
        return MsgBox("Error establishing default browser path.")
    }
}
