#Requires AutoHotkey v2.0
#SingleInstance Force

; Array of windows to ignore
ignoredWindows := ["ahk_exe code.exe"]

; Function to check if any of the specified windows is active
IsIgnoredWindowActive() {
    for window in ignoredWindows {
        if (WinActive(window))
            return true
    }
    return false
}

$!WheelUp::
{
    if (!IsIgnoredWindowActive()) {
        Send("{WheelUp 4}")
    }
    return
}

$!WheelDown::
{
    if (!IsIgnoredWindowActive()) {
        Send("{WheelDown 4}")
    }
    return
}
