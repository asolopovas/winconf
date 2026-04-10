#Requires AutoHotkey v2.0

GetTargetKey(val) {
    return SubStr(val, StrLen(val), 1)
}

GetActiveWindowID() => "ahk_id " Format("0x{:X}", WinActive("A"))

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

    return filePath
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

    ; Delete file in background after a delay to let AIMP release it
    deleteFunc := DeleteFileDelayed.Bind(filePath)
    SetTimer(deleteFunc, -2000)
}

DeleteFileDelayed(filePath) {
    if !FileExist(filePath) {
        ToolTip("File not found:`n" . filePath)
        SetTimer(() => ToolTip(), -3000)
        return
    }
    try {
        FileDelete(filePath)
        ToolTip("Deleted:`n" . filePath)
    } catch as err {
        ToolTip("Delete failed:`n" . err.Message)
    }
    SetTimer(() => ToolTip(), -3000)
}
