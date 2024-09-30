Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineKeyHandler -Chord 'Ctrl+l' -ScriptBlock {
    $line = $null
    $cursor = $null
    #get the current line
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardKillLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line)
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+u' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardKillLine()
}
