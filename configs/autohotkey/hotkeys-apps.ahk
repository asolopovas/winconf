RunOrActivate(windowID, exePath, args, runAsAdmin, alwaysNewInstance) {
    if WinExist(windowID) and !alwaysNewInstance {
        If WinActive(windowID) {
            WinMinimize, % "ahk_id " . WinExist(windowID)  ; specify window to minimize
        } else {
            WinActivate, %windowID%
        }
    } else {
        if (runAsAdmin) {
            Run *RunAs %exePath% %args%
        } else {
            RunAsUser(exePath, args)
        }
        WinWait, %windowID%
        WinActivate, %windowID%
    }
}

RunOrActivateTerminal(windowTitle, runAsAdmin := false, alwaysNewInstance := false) {

    EnvGet, username, username
    terminalPath := "C:\Users\" username "\AppData\Local\Microsoft\WindowsApps\wt.exe"
    args := "-w """ windowTitle """ nt -p """ windowTitle """ --suppressApplicationTitle"
    windowID := windowTitle " ahk_class CASCADIA_HOSTING_WINDOW_CLASS"

    RunOrActivate(windowID, terminalPath, args, runAsAdmin, alwaysNewInstance )
}

F12::
    RunOrActivateTerminal("PowerShell")
return

+F12::
    RunOrActivateTerminal("PowerShell Admin", true)
return

#Enter::
    RunOrActivateTerminal("Ubuntu")
return

#+Enter::
    RunOrActivateTerminal("Ubuntu", true)
return

#c::
    windowID := "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"
    exePath := "C:\Program Files\Google\Chrome\Application\chrome.exe"
    RunOrActivate(windowId, itemPath, "", runAsAdmin, alwaysNewInstance)
Return

#m::
    windowID := "ahk_class Chrome_WidgetWin_0 ahk_exe Spotify.exe"
    exePath := A_AppData "\Spotify\Spotify.exe"

    if !FileExist(exePath) {
        RunAsUser("winget install --id Spotify.Spotify")
        WinWait, ahk_exe winget.exe
        WinWaitClose, ahk_exe winget.exe
    }

    if WinExist(windowID) {
        if WinActive(windowID) {
            PostMessage, 0x112, 0xF060,,, % "ahk_id " WinActive("A")
        } else {
            WinActivate
        }
    } else {
        Run, % exePath
    }
Return
