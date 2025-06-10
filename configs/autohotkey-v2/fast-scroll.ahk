#Requires AutoHotkey v2.0
#SingleInstance Force

ignoredWindows := ["ahk_exe Code.exe"]

; Function to check if any of the specified windows is active
IsIgnoredWindowActive() {
    for window in ignoredWindows {
        if WinActive(window)
            return true
    }
    return false
}

; Function to check if the current window is NOT in the ignore list
ShouldScrollHotkeyBeActive(*) {
    return !IsIgnoredWindowActive()
}

HotIf ShouldScrollHotkeyBeActive
$!WheelUp::Send("{WheelUp 6}")
$!WheelDown::Send("{WheelDown 6}")
HotIf  ; Reset to default
