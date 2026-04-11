#Requires AutoHotkey v2.0

GetTargetKey(val) {
    return SubStr(val, StrLen(val), 1)
}

GetActiveWindowID() => "ahk_id " Format("0x{:X}", WinActive("A"))

AIMPDebugLogPath() => A_Temp . "\aimp-delete-debug.log"

AIMPDebugLog(tag, info := "") {
    line := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " [" . tag . "] " . info . "`n"
    try FileAppend(line, AIMPDebugLogPath(), "UTF-8")
}

GetAIMPCurrentFile() {
    hMap := DllCall("OpenFileMapping", "UInt", 4, "Int", 0, "Str", "AIMP2_RemoteInfo", "Ptr")
    if (!hMap)
        return ""

    ptr := DllCall("MapViewOfFile", "Ptr", hMap, "UInt", 4, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
    if (!ptr) {
        DllCall("CloseHandle", "Ptr", hMap)
        return ""
    }

    headerSize := NumGet(ptr, 0, "Int")
    albumLen := NumGet(ptr, 40, "Int")
    artistLen := NumGet(ptr, 44, "Int")
    dateLen := NumGet(ptr, 48, "Int")
    fileNameLen := NumGet(ptr, 52, "Int")

    ; Data order: Album, Artist, Date, FileName (each char is 2 bytes UTF-16)
    dataOffset := headerSize + (albumLen + artistLen + dateLen) * 2
    filePath := StrGet(ptr + dataOffset, fileNameLen, "UTF-16")

    DllCall("UnmapViewOfFile", "Ptr", ptr)
    DllCall("CloseHandle", "Ptr", hMap)

    return Trim(filePath, " `t`r`n")
}

ToLongPath(path) {
    if (SubStr(path, 1, 4) = "\\?\")
        return path
    if (SubStr(path, 1, 2) = "\\")
        return "\\?\UNC\" . SubStr(path, 3)
    if (RegExMatch(path, "^[A-Za-z]:\\"))
        return "\\?\" . path
    return path
}

Win32FileExists(path) {
    attrs := DllCall("GetFileAttributesW", "Str", path, "UInt")
    return attrs != 0xFFFFFFFF
}

Win32DeleteFile(path) {
    return DllCall("DeleteFileW", "Str", path, "Int") != 0
}

AIMPDeleteCurrentAndSkip() {
    filePath := GetAIMPCurrentFile()
    if (filePath = "") {
        ToolTip("No track info from AIMP")
        SetTimer(() => ToolTip(), -2000)
        return
    }

    ; Skip to next track first so AIMP releases the file
    Send("{Media_Next}")

    ; Delete file in background after a delay so AIMP releases it
    SetTimer(() => DeleteTrackFile(filePath), -2000)
}

DeleteTrackFile(filePath) {
    lastErr := 0
    for path in [filePath, ToLongPath(filePath)] {
        if (!Win32FileExists(path))
            continue
        if (Win32DeleteFile(path)) {
            ToolTip("Deleted:`n" . filePath)
            SetTimer(() => ToolTip(), -3000)
            return
        }
        lastErr := A_LastError
    }

    ; Direct delete failed. When AHK runs elevated, UNC credentials cached in
    ; the interactive token aren't available here, so GetFileAttributesW and
    ; DeleteFileW against \\NAS fail. Re-run the delete as the interactive user.
    if (A_IsAdmin) {
        try {
            RunAsUser(A_ComSpec, '/c del /f /q "' . filePath . '"')
            AIMPDebugLog("fallback-runasuser", "path=" . filePath)
            ToolTip("Delete via user session:`n" . filePath)
            SetTimer(() => ToolTip(), -3000)
            return
        } catch as err {
            AIMPDebugLog("fallback-error", "err=" . err.Message)
        }
    }

    AIMPDebugLog("delete-failed",
        "path=" . filePath . " lastError=" . lastErr . " isAdmin=" . A_IsAdmin)
    ToolTip("Delete failed (log: " . AIMPDebugLogPath() . "):`n" . filePath)
    SetTimer(() => ToolTip(), -5000)
}
