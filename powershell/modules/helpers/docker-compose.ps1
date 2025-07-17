function Dc {
    docker compose @args
}

Set-Alias -Name dc -Value Dc

Register-ArgumentCompleter -CommandName 'Dc' -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $commands = @(
        'build', 'config', 'cp', 'create', 'down', 'events', 'exec', 'images', 'kill', 'logs', 'ls', 'pause', 'port',
        'ps', 'pull', 'push', 'restart', 'rm', 'run', 'start', 'stop', 'top', 'unpause', 'up', 'version'
    )

    $completions = $commands |
        Where-Object { $_.StartsWith($wordToComplete) } |
        ForEach-Object { New-CompletionResult -CompletionText $_ -ToolTip $_ }

    $completions
}
