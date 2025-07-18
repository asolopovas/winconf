#Requires AutoHotkey v2.0

global ENABLE_DEBUG := false
global DEBUG_LOG_FILE := "C:\Users\" . A_UserName . "\winconf\logs\terminal_debug.md"
global ENABLE_KEY_LOGGING := false

; F1::
; {
;     global ENABLE_DEBUG, ENABLE_KEY_LOGGING, DEBUG_LOG_FILE
;     ENABLE_DEBUG := !ENABLE_DEBUG

;     if (ENABLE_DEBUG) {
;         logDir := StrReplace(DEBUG_LOG_FILE, "terminal_debug.md", "")
;         try {
;             DirCreate(logDir)
;         }

;         result := MsgBox("Clear existing debug logs before starting new session?", "Debug Mode", "YesNo Icon?")
;         if (result = "Yes") {
;             ClearDebugLogs()
;         }

;         ENABLE_KEY_LOGGING := True

;         try {
;             WriteTableHeader()

;             MsgBox("Debug Mode: ENABLED`n`nKey Logging: " . (ENABLE_KEY_LOGGING ? "ON" : "OFF") . "`n`nDebug log: " .
;             DEBUG_LOG_FILE . "`n`nF1: Toggle Debug`n`nCtrl+Win+Alt+R: Restart Script", "Debug Mode", "Icon! T5")
;         } catch as err {
;             MsgBox("Failed to create debug log: " . err.Message . "`nPath: " . DEBUG_LOG_FILE, "Debug Error", "Icon!")
;         }
;     } else {
;         ENABLE_KEY_LOGGING := false
;         MsgBox("Debug Mode: DISABLED`n`nLogs preserved. Use F1 again to clear on next enable.", "Debug Mode",
;             "Icon! T2")
;     }
; }

if (ENABLE_DEBUG) {
    try {
        FileAppend("# Terminal Debug Log`n`n**Started:** " . A_Now . "`n", DEBUG_LOG_FILE)
    }
}

DebugLog(category, params*) {
    global ENABLE_DEBUG, DEBUG_LOG_FILE
    if (!ENABLE_DEBUG) {
        return
    }

    timestamp := FormatTime(A_Now, "HH:mm:ss.") . A_MSec
    message := FormatLogMessage(category, timestamp, params*)
    logEntry := message . "`n"

    try {
        FileAppend(logEntry, DEBUG_LOG_FILE)
    } catch as err {
        MsgBox("Debug log error: " . err.Message . "`nFile: " . DEBUG_LOG_FILE, "Debug Error", "Icon!")
    }
}

WriteTableHeader() {
    global DEBUG_LOG_FILE, COLUMN_WIDTHS, COLUMN_NAMES
    currentTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

    header := "## Debug Log - " . currentTime . "`n`n| "

    for i, name in COLUMN_NAMES {
        paddedName := PadString(name, COLUMN_WIDTHS[i])
        header .= paddedName . " | "
    }
    header := SubStr(header, 1, -3) . " |`n"

    separator := GenerateTableSeparator() . "`n"

    try {
        FileAppend(header . separator, DEBUG_LOG_FILE)
    }
}

global COLUMN_WIDTHS := [13, 7, 8, 15, 6, 13, 9, 5, 40]
global COLUMN_NAMES := ["Time", "ahk_id", "Category", "Action", "MinMax", "Pos", "Size", "Count", "Process"]

PadString(str, length, char := " ") {
    str := String(str)
    while (StrLen(str) < length) {
        str .= char
    }
    return str
}

GetProcessPath(processName) {
    if (processName = "" || processName = "-") {
        return "-"
    }

    try {
        for objItem in ComObjGet("winmgmts:").ExecQuery("SELECT ExecutablePath FROM Win32_Process WHERE Name = '" .
            processName . "'") {
            if (objItem.ExecutablePath) {
                return objItem.ExecutablePath
            }
        }
    } catch {
        return processName
    }

    return processName
}

GenerateTableSeparator() {
    global COLUMN_WIDTHS
    separator := "| "

    for i, width in COLUMN_WIDTHS {
        separator .= PadString("", width, "-") . " | "
    }

    return RTrim(separator, " | ") . " |"
}

FormatTableRow(time, ahk_id, category, action, minmax, pos, size, count, process) {
    global COLUMN_WIDTHS
    values := [time, ahk_id, category, action, minmax, pos, size, count, process]

    result := "| "
    for i, value in values {
        result .= PadString(value, COLUMN_WIDTHS[i]) . " | "
    }

    return RTrim(result, " | ") . " |"
}

FormatLogMessage(category, timestamp, params*) {
    switch category {
        case "TOGGLE":
            processPath := GetProcessPath(params[3])
            return FormatTableRow(timestamp, params[2], "TOGGLE", params[1], "-", "-", "-", "-", processPath)
        case "TOGGLE_MINIMIZE":
            processPath := GetProcessPath("wezterm-gui.exe")
            return FormatTableRow(timestamp, params[1], "TOGGLE", "minimizing", "-", "-", "-", "-", processPath)
        case "TOGGLE_ACTIVATE":
            processPath := GetProcessPath("wezterm-gui.exe")
            return FormatTableRow(timestamp, params[1], "TOGGLE", "activating", params[2], params[3] . "," . params[4],
                params[5] . "x" . params[6], "-", processPath)
        case "TOGGLE_LAUNCH":
            return FormatTableRow(timestamp, "-", "TOGGLE", "launching", "-", "-", "-", "-", "-")
        case "LAUNCH":
            processPath := GetProcessPath(params[3])
            return FormatTableRow(timestamp, params[2], "LAUNCH", params[1], "-", "-", "-", "-", processPath)
        case "LAUNCH_FOUND":
            return FormatTableRow(timestamp, "-", "LAUNCH", "found_wezterm", "-", "-", "-", "-", "-")
        case "LAUNCH_RUNNING":
            return FormatTableRow(timestamp, "-", "LAUNCH", "running_cmd", "-", "-", "-", params[1], "-")
        case "LAUNCH_SUCCESS":
            processPath := GetProcessPath("wezterm-gui.exe")
            return FormatTableRow(timestamp, params[1], "LAUNCH", "launched", params[4], params[5] . "," . params[6],
                params[7] . "x" . params[8], params[2] . "->" . params[3], processPath)
        case "LAUNCH_ACTIVATED":
            processPath := GetProcessPath("wezterm-gui.exe")
            return FormatTableRow(timestamp, params[1], "LAUNCH", "activated", "-", "-", "-", "-", processPath)
        case "LAUNCH_TIMEOUT":
            return FormatTableRow(timestamp, "-", "LAUNCH", "ERROR", "-", "-", "-", "-", "-")
        case "LAUNCH_NOT_FOUND":
            return FormatTableRow(timestamp, "-", "LAUNCH", "ERROR", "-", "-", "-", "-", "-")
        case "STATUS":
            processPath := GetProcessPath(params[2])
            return FormatTableRow(timestamp, params[1], "STATUS", "check", "-", "-", "-", params[3], processPath)
        case "STATUS_WINDOWS":
            return FormatTableRow(timestamp, "-", "STATUS", "windows", "-", "-", "-", "-", "-")
        case "STATUS_DETAILED":
            return FormatTableRow(timestamp, "-", "STATUS", "detailed", "-", "-", "-", "-", "-")
        case "KEY":
            processPath := GetProcessPath(params[3])
            return FormatTableRow(timestamp, params[2], "KEY", params[1], "-", "-", "-", "-", processPath)
        default:
            return FormatTableRow(timestamp, "-", category, params[1], "-", "-", "-", "-", "-")
    }
}

ClearDebugLogs() {
    global DEBUG_LOG_FILE

    try {
        FileDelete(DEBUG_LOG_FILE)
        FileAppend("", DEBUG_LOG_FILE)
    } catch as err {
    }
}

KeyLogger(ThisHotkey) {
    global ENABLE_DEBUG, ENABLE_KEY_LOGGING
    if (!ENABLE_DEBUG || !ENABLE_KEY_LOGGING) {
        return
    }

    currentWin := WinGetID("A")
    currentProcessName := ""
    try {
        currentProcessName := WinGetProcessName("A")
    }
    DebugLog("KEY", ThisHotkey, currentWin, currentProcessName)
}
