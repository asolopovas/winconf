Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $local:word = $wordToComplete.Replace('"', '""')
    $local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$local:word" --commandline "$local:ast" --position $cursorPosition |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
