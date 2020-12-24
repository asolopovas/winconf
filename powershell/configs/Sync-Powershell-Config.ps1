$src = [environment]::getfolderpath("mydocuments") + "\WindowsPowerShell"
$target =  (get-item $PSScriptRoot ).parent.FullName

Sync-Config $src $target

# Install Fzf
choco install fzf -y | Out-Null
Install-Module -Name PSFzf -RequiredVersion 2.1.0
