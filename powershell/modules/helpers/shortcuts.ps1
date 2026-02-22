$fzfCmd = Get-Command fzf -ErrorAction SilentlyContinue
if (-not $fzfCmd) {
    $fzfPkg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "junegunn.fzf*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($fzfPkg) { $env:PATH += ";$($fzfPkg.FullName)" }
}

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf -ErrorAction SilentlyContinue

    if (Get-Module PSFzf) {
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
}
