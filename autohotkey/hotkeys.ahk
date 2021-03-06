#Include helpers/runasuser.ahk

+F12::
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
    DllCall("LockWorkStation")
    sleep, 1000
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
return

;::WinMaximize, A

#f::
    WinGet MMX, MinMax, A
    IfEqual MMX,0, WinMaximize, A
    IfEqual MMX,1, WinRestore, A
Return
; --------------------------------------
; Application Shortuts
; --------------------------------------

#b::
    if WinExist("ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe") {
        If WinActive("ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"){
            WinMinimize
        } else {
            WinActivate
        }
    } else {
        RunAsUser("C:\Program Files\Google\Chrome\Application\chrome.exe")
    }
Return

#m::
    if WinExist("ahk_class Chrome_WidgetWin_0 ahk_exe Spotify.exe") {
        If WinActive("ahk_class Chrome_WidgetWin_0 ahk_exe Spotify.exe") {
            WinMinimize
        } else {
            WinActivate
        }
    } else {
        EnvGet, vUserProfile, USERPROFILE
        path = "%vUserProfile%\AppData\Roaming\Spotify\Spotify.exe"
        RunAsUser(path)
    }
Return

#Enter::
    if WinExist("Administrator: Windows PowerShell")
        WinActivate ;
    else {
        Run, "wt.exe"
        WinWait, Administrator: Windows PowerShell, , 3
        WinActivate ;
    }
return

#+Enter::
    if WinExist("~")
        WinActivate ;
    else {
        Run "wt.exe" -p "Ubuntu"
        WinWait, ~, , 3
        WinActivate ;
    }
return

#q::
    WinGetTitle, Title, A
    PostMessage, 0x112, 0xF060,,, %Title%
return

; --------------------------------------
; Navigation
; --------------------------------------
#h::#Left
#j::#Down
#k::#Up
#l::#Right

LWin & u::AltTab
LWin & i::ShiftAltTab
