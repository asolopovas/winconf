#Include "./hotkey-desktop-switcher.ahk"

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
        windowId := "ahk_exe " exeName

        RunOrActivate(windowId, defaultBrowserPath, "")
    }

#m::
    {
        windowID := "ahk_class TAIMPMainForm ahk_exe AIMP.exe"
        exePath := "C:\\Program Files\\AIMP\\AIMP.exe"
        RunOrActivate(windowID, exePath, "")
    }



#f::
{
    MMX := WinGetMinMax("A")
    if (MMX = 0)
    {
        WinMaximize("A")
    }
    else if (MMX = 1)
    {
        WinRestore("A")
    }
}

#q::
    {
        Title := WinGetTitle("A")
        PostMessage(0x112, 0xF060, , , Title)
        return

        #SingleInstance force
    }

~^s::
    {
        if WinActive("hotkeys.ahk - winconf - Visual Studio Code")
        {
            Sleep(200)
            Reload()
        }
        else if WinActive("hotkeys-desktop-switcher.ahk - winconf - Visual Studio Code")
        {
            Sleep(200)
            Reload()
        }
        else if WinActive("load.ahk - winconf - Visual Studio Code")
        {
            Sleep(200)
            Reload()
        }
        return
    }

!+F11::
{
    RestartExplorer()
    Return
}

!.::
{
    CycleWindowsWithinSameClass(-1)
}
!,::
{
    CycleWindowsWithinSameClass(+1)
}



; #m::
;     {
;         windowID := "ahk_exe Spotify.exe"
;         exePath := A_AppData . "\\Spotify\\Spotify.exe"

;         if (!WinExist(windowID)) {
;             RunAsUser(exePath)
;             WinWait(windowID)
;         } else {
;             if (WinActive(windowID)) {
;                 PostMessage(0x112, 0xF060, , , "ahk_id " . WinActive("A"))
;             } else {
;                 WinActivate
;             }
;         }

;     }
