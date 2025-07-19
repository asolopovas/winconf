# Fix for duplicate cd completions in PSReadLine
# Force PSReadLine to use MenuComplete but with custom behavior
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
}

# Hook into the completion process to filter duplicates
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    # Ensure our settings stick after all modules load
    Set-PSReadLineOption -CompletionQueryItems 50 -ShowToolTips:$false
}