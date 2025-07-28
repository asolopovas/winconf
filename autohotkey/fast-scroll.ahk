#Requires AutoHotkey >=2.0
#SingleInstance

Speed := 7

; Alt + Shift + Wheel up/down
+!WheelDown::Send("{WheelDown " Speed "}")
+!WheelUp::Send("{WheelUp " Speed "}")
