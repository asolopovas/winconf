if (Get-Module -Name PSFzf -ListAvailable) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border'
    $env:FZF_ALT_C_COMMAND = 'fd --type directory --hidden --exclude AppData --exclude .git --exclude .vs --exclude node_modules --exclude .vscode --exclude "Application Data" --exclude "Local Settings" --exclude Cookies --exclude Recent --exclude SendTo --exclude "Start Menu" --exclude Templates --exclude NetHood --exclude PrintHood --exclude "Temporary Internet Files" --exclude "3D Objects" --exclude "Saved Games" --exclude Links --exclude Favorites --exclude Contacts --exclude Searches'
    
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r' -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordSetLocation 'Alt+c'
}
