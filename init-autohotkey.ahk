#Requires AutoHotkey v2.0

; Special Keys: https://autohotkey.com/docs/Hotkeys.htm
; ! = alt
; + = shift
; ^ = ctrl
; # = win

F8:: Reload

#Include "autohotkey/runasuser.ahk"
#Include "autohotkey/system.ahk"
#Include "autohotkey/window-management.ahk"
#Include "autohotkey/helpers.ahk"
#Include "autohotkey/debug.ahk"
#Include "autohotkey/terminal.ahk"
#Include "autohotkey/fast-scroll.ahk"
#Include "autohotkey/hotkeys.ahk"

SetKeyDelay(0, 50)
