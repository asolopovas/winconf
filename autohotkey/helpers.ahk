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
    fileSize := NumGet(ptr, 20, "Int64")
    albumLen := NumGet(ptr, 40, "Int")
    artistLen := NumGet(ptr, 44, "Int")
    dateLen := NumGet(ptr, 48, "Int")
    fileNameLen := NumGet(ptr, 52, "Int")

    dataOffset := headerSize + (albumLen + artistLen + dateLen) * 2
    filePath := StrGet(ptr + dataOffset, fileNameLen, "UTF-16")

    DllCall("UnmapViewOfFile", "Ptr", ptr)
    DllCall("CloseHandle", "Ptr", hMap)

    info.path := Trim(filePath, " `t`r`n")
    if (fileSize > 0 && fileSize < 0x10000000000)
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

Win32FileExistsAny(path) {
    for candidate in [path, ToLongPath(path)] {
        if Win32FileExists(candidate)
            return true
    }
    return false
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

AIMPPostCommand(commandID) {
    hwnd := WinExist(AIMPWindowID())
    if (!hwnd)
        return false
    return DllCall("PostMessageW", "Ptr", hwnd, "UInt", 0x111, "UPtr", commandID, "Ptr", 0, "Int") != 0
}

AIMPNextTrack() {
    if !AIMPPostCommand(0x0C50)
        Send("{Media_Next}")
}

AIMPRemoveMissingFiles() {
    AIMPPostCommand(0x0D48)
}

AIMPDeleteCurrentAndSkip() {
    info := GetAIMPCurrentFile()
    if (info.path = "") {
        ToolTip("No track info from AIMP")
        SetTimer(() => ToolTip(), -2000)
        return
    }

    label := FormatTrackLabel(info)
    AIMPNextTrack()
    if Win32FileExistsAny(info.path) {
        SetTimer(() => DeleteTrackFile(info.path, label), -2000)
        return
    }

    AIMPDebugLog("file-already-missing", "path=" . info.path)
    AIMPRemoveMissingFiles()
    ToolTip("Already missing: " . label)
    SetTimer(() => ToolTip(), -3000)
}

DeleteTrackFile(filePath, label) {
    for path in [filePath, ToLongPath(filePath)] {
        if (Win32DeleteFile(path)) {
            AIMPRemoveMissingFiles()
            ToolTip("Deleted: " . label)
            SetTimer(() => ToolTip(), -3000)
            return
        }
    }
    lastErr := A_LastError

    if (A_IsAdmin) {
        try {
            Func("RunAsUser").Call(A_ComSpec, '/c del /f /q "' . filePath . '"')
            AIMPDebugLog("fallback-runasuser", "path=" . filePath)
            SetTimer(() => AIMPRemoveMissingFiles(), -2000)
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
