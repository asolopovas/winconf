#Requires AutoHotkey v2.0

RunAsUser(Target, Arguments:="", WorkingDirectory:="")
{
	static TASK_TRIGGER_REGISTRATION := 7   ; trigger on registration.
	static TASK_ACTION_EXEC := 0  ; specifies an executable action.
	static TASK_CREATE := 2
	static TASK_RUNLEVEL_LUA := 0
	static TASK_LOGON_INTERACTIVE_TOKEN := 3
	objService := ComObject("Schedule.Service")
	objService.Connect()

	objFolder := objService.GetFolder("\")  ; Fixed this line
	objTaskDefinition := objService.NewTask(0)

	principal := objTaskDefinition.Principal
	principal.LogonType := TASK_LOGON_INTERACTIVE_TOKEN    ; Set the logon type to TASK_LOGON_PASSWORD
	principal.RunLevel := TASK_RUNLEVEL_LUA  ; Tasks will be run with the least privileges.

	colTasks := objTaskDefinition.Triggers
	objTrigger := colTasks.Create(TASK_TRIGGER_REGISTRATION)
	endTime := A_Now ; Get the current system time
	endTime := DateAdd(endTime, 1, "Minutes")  ;end time = 1 minutes from now
	endTime := FormatTime(endTime, "yyyy-MM-ddTHH`:mm`:ss")
	objTrigger.EndBoundary := endTime
	colActions := objTaskDefinition.Actions
	objAction := colActions.Create(TASK_ACTION_EXEC)
	objAction.ID := "7plus run"
	objAction.Path := Target
	objAction.Arguments := Arguments
	objAction.WorkingDirectory := WorkingDirectory ? WorkingDirectory : A_WorkingDir
	objInfo := objTaskDefinition.RegistrationInfo
	objInfo.Author := "7plus"
	objInfo.Description := "Runs a program as non-elevated user"
	objSettings := objTaskDefinition.Settings
	objSettings.Enabled := True
	objSettings.Hidden := False
	objSettings.DeleteExpiredTaskAfter := "PT0S"
	objSettings.StartWhenAvailable := True
	objSettings.ExecutionTimeLimit := "PT0S"
	objSettings.DisallowStartIfOnBatteries := False
	objSettings.StopIfGoingOnBatteries := False
	objFolder.RegisterTaskDefinition("", objTaskDefinition, TASK_CREATE , "", "", TASK_LOGON_INTERACTIVE_TOKEN )
}
