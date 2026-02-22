$root = Join-Path $env:USERPROFILE 'winconf'
$psdir = Join-Path $root 'powershell'

try {
    . $root\functions.ps1
    . $psdir\modules\aliases\remove-aliases.ps1
    Import-Module $psdir\modules\aliases
    . $psdir\modules\helpers\shortcuts.ps1
} catch {
    Write-Warning "Error loading PowerShell modules: $_"
}

try {
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Key Alt+d -Function DeleteWord
} catch {}

foreach ($mod in @('posh-git', 'Terminal-Icons', 'ZLocation', 'DockerCompletion')) {
    if (Get-Module -Name $mod -ListAvailable -ErrorAction SilentlyContinue) {
        Import-Module $mod
    }
}

if (Get-Module -Name posh-git) {
    $env:POSH_GIT_ENABLED = $false
}

Get-ChildItem "$psdir\completions\*.ps1" | ForEach-Object { . $_.FullName }

$ENV:STARSHIP_CONFIG = Join-Path $psdir 'configs\starship.toml'
$Host.UI.RawUI.WindowTitle = "PowerShell"
try { $null = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

if (Test-CommandExists starship) {
    try { Invoke-Expression (&starship init powershell) }
    catch { Write-Warning "Error initializing Starship: $_" }
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $ptPath = Join-Path $env:LOCALAPPDATA 'PowerToys\WinGetCommandNotFound.psd1'
    if (Test-Path $ptPath) {
        try { Import-Module $ptPath } catch {}
    }
}

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
