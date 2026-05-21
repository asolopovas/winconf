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

AIMPWindowID() => "ahk_class TAIMPMainForm ahk_exe AIMP.exe"

GetAIMPCurrentFile() {
    info := { path: "", sizeBytes: 0 }
    hMap := DllCall("OpenFileMapping", "UInt", 4, "Int", 0, "Str", "AIMP2_RemoteInfo", "Ptr")
    if (!hMap)
        return info

    ptr := DllCall("MapViewOfFile", "Ptr", hMap, "UInt", 4, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
    if (!ptr) {
        DllCall("CloseHandle", "Ptr", hMap)
        return info
    }

    headerSize := NumGet(ptr, 0, "Int")
    fileSize := NumGet(ptr, 20, "Int64")  ; AIMP2_FileInfo.FileSize (packed, so Int64 sits at offset 20, not 24)
    albumLen := NumGet(ptr, 40, "Int")
    artistLen := NumGet(ptr, 44, "Int")
    dateLen := NumGet(ptr, 48, "Int")
    fileNameLen := NumGet(ptr, 52, "Int")

    ; Data order: Album, Artist, Date, FileName (each char is 2 bytes UTF-16)
    dataOffset := headerSize + (albumLen + artistLen + dateLen) * 2
    filePath := StrGet(ptr + dataOffset, fileNameLen, "UTF-16")

    DllCall("UnmapViewOfFile", "Ptr", ptr)
    DllCall("CloseHandle", "Ptr", hMap)

    info.path := Trim(filePath, " `t`r`n")
    if (fileSize > 0 && fileSize < 0x10000000000)  ; sanity: < 1 TB
        info.sizeBytes := fileSize
    return info
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

FormatTrackLabel(info) {
    SplitPath(info.path, &trackName)
    if (info.sizeBytes > 0)
        return trackName . Format(" ({:.1f} MB)", info.sizeBytes / 1048576)
    return trackName
}

AIMPDeleteCurrentAndSkip() {
    info := GetAIMPCurrentFile()
    if (info.path = "") {
        ToolTip("No track info from AIMP")
        SetTimer(() => ToolTip(), -2000)
        return
    }

    label := FormatTrackLabel(info)
    if (AIMPDeleteCurrentWithPlayer()) {
        SetTimer(() => VerifyAIMPDeleted(info.path, label), -2500)
        return
    }

    Send("{Media_Next}")
    SetTimer(() => DeleteTrackFile(info.path, label), -2000)
}

AIMPDeleteCurrentWithPlayer() {
    windowID := AIMPWindowID()
    if !WinExist(windowID)
        return false

    activeID := GetActiveWindowID()
    try {
        WinActivate(windowID)
        if !WinWaitActive(windowID, , 2) {
            AIMPRestoreActiveWindow(activeID)
            return false
        }
        Send("!{Del}")
        Sleep(150)
        Send("{Enter}")
        Sleep(300)
        AIMPRestoreActiveWindow(activeID)
        return true
    } catch as err {
        AIMPRestoreActiveWindow(activeID)
        AIMPDebugLog("ui-delete-error", "err=" . err.Message)
        return false
    }
}

AIMPRestoreActiveWindow(activeID) {
    if (activeID != "" && WinExist(activeID) && !WinActive(activeID))
        WinActivate(activeID)
}

VerifyAIMPDeleted(filePath, label) {
    if !Win32FileExists(filePath) {
        ToolTip("Deleted: " . label)
        SetTimer(() => ToolTip(), -3000)
        return
    }

    AIMPDebugLog("ui-delete-fallback", "path=" . filePath)
    Send("{Media_Next}")
    SetTimer(() => DeleteTrackFile(filePath, label), -2000)
}

DeleteTrackFile(filePath, label) {
    for path in [filePath, ToLongPath(filePath)] {
        if (Win32DeleteFile(path)) {
            ToolTip("Deleted: " . label)
            SetTimer(() => ToolTip(), -3000)
            return
        }
    }
    lastErr := A_LastError

    ; Direct delete failed. When AHK runs elevated, UNC credentials cached in
    ; the interactive token aren't available here, so DeleteFileW against
    ; \\NAS fails. Re-run the delete as the interactive user.
    if (A_IsAdmin) {
        try {
            Func("RunAsUser").Call(A_ComSpec, '/c del /f /q "' . filePath . '"')
            AIMPDebugLog("fallback-runasuser", "path=" . filePath)
            ToolTip("Deleted: " . label)
            SetTimer(() => ToolTip(), -3000)
            return
        } catch as err {
            AIMPDebugLog("fallback-error", "err=" . err.Message)
        }
    }

    AIMPDebugLog("delete-failed",
        "path=" . filePath . " lastError=" . lastErr . " isAdmin=" . A_IsAdmin)
    ToolTip("Delete failed: " . label)
    SetTimer(() => ToolTip(), -5000)
}
