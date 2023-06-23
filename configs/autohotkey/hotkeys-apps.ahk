RunOrActivate(windowID, terminalPath, args, alwaysNewInstance, runAsAdmin) {
    if WinExist(windowID) and !alwaysNewInstance {
        If WinActive(windowID) {
            WinMinimize
        } else {
            WinActivate, %windowID%
        }
    } else {
        if (runAsAdmin) {
            Run *RunAs %terminalPath% %args%
        } else {
            RunAsUser(terminalPath, args)
        }
        WinWait, %windowID%
        WinActivate, %windowID%
    }
}

RunOrActivateTerminal(windowTitle, alwaysNewInstance := false, runAsAdmin := false) {
    EnvGet, username, username
    terminalPath := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    args := "-w " windowTitle " nt -p " windowTitle " --title " windowTitle " --suppressApplicationTitle"
    windowID := windowTitle " ahk_class CASCADIA_HOSTING_WINDOW_CLASS"
    if (runAsAdmin) {
        windowID := "Administrator: " . windowTitle
    }

    RunOrActivate(windowID, terminalPath, args, alwaysNewInstance, runAsAdmin)
}

RunOrActivateApplication(itemClass, itemPath, alwaysNewInstance := false, runAsAdmin := false) {
    windowID := itemClass
    RunOrActivate(windowID, itemPath, "", alwaysNewInstance, runAsAdmin)
}

RunOrActivateSpotify(itemClass, itemPath) {
    windowID := itemClass
    if WinExist(windowID) {
        if WinActive(windowID) {
            PostMessage, 0x112, 0xF060,,, % "ahk_id " WinActive("A")
        } else {
            WinActivate
        }
    } else {
        Run, % itemPath
    }
}

F8::
    RunOrActivateTerminal("PowerShell")
return

F9::
    RunOrActivateTerminal("Ubuntu")
return

+F8::
    RunOrActivateTerminal("PowerShell", true)
return

+F9::
    RunOrActivateTerminal("Ubuntu", true)
return

F10::
    RunOrActivateTerminal("PowerShell", true, true)
return

^Enter::
    RunOrActivateTerminal("Ubuntu", true)
return

^+Enter::
    RunOrActivateTerminal("Ubuntu")
return
#c::
    chromeClass := "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"
    chromePath := "C:\Program Files\Google\Chrome\Application\chrome.exe"
    runOrActivateApplication(chromeClass, chromePath)
Return

#m::
    spotifyClass := "ahk_class Chrome_WidgetWin_0 ahk_exe Spotify.exe"
    spotifyPath := A_AppData "\Spotify\Spotify.exe"

    if !FileExist(spotifyPath) {
        RunAsUser("winget install --id Spotify.Spotify")
        WinWait, ahk_exe winget.exe
        WinWaitClose, ahk_exe winget.exe
    }

    runOrActivateSpotify(spotifyClass, spotifyPath)
Return
