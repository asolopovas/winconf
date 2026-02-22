Register-ArgumentCompleter -CommandName ssh, scp, sftp -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $configFile = Join-Path $env:USERPROFILE '.ssh\config'
    if (Test-Path $configFile) {
        Get-Content $configFile |
            Select-String '^\s*Host\s+(.+)' |
            ForEach-Object { $_.Matches[0].Groups[1].Value -split '\s+' } |
            Where-Object { $_ -notmatch '[*?]' -and $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
}
