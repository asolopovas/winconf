if (Get-Module -Name PSFzf -ListAvailable) {
    Import-Module PSFzf -ErrorAction SilentlyContinue

    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border'

    $excludeDirs = @(
        'AppData', '.git', '.vs', 'node_modules', '.vscode',
        'Application Data', 'Local Settings', 'Cookies', 'Recent',
        'SendTo', 'Start Menu', 'Templates', 'NetHood', 'PrintHood',
        'Temporary Internet Files', '3D Objects', 'Saved Games',
        'Links', 'Favorites', 'Contacts', 'Searches',
        '.cache', '.conda', '.cursor', '.bun', '.aws', '.azure',
        '.amp', '.docker', '.local', '.redhat', '.ScreamingFrogSEOSpider',
        'vscode-remote-wsl', 'wslu', 'miniconda3'
    )

    $excludeFlags = $excludeDirs | ForEach-Object { "--exclude `"$_`"" }
    $env:FZF_ALT_C_COMMAND = "fd --type directory --max-depth 4 $($excludeFlags -join ' ')"

    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r' -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordSetLocation 'Alt+c'
}
