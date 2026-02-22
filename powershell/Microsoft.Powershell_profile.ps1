$root = [System.IO.Path]::Combine($env:USERPROFILE, 'winconf')
$psdir = [System.IO.Path]::Combine($root, 'powershell')

try {
    . $root\functions.ps1
    . $psdir\modules\aliases\remove-aliases.ps1
    Import-Module $psdir\modules\aliases
} catch {
    Write-Warning "Error loading PowerShell modules: $_"
}

$ENV:STARSHIP_CONFIG = [System.IO.Path]::Combine($psdir, 'configs\starship.toml')
$Host.UI.RawUI.WindowTitle = "PowerShell"
try { $null = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$global:_profileInitialized = $false
function global:Initialize-Profile {
    if ($global:_profileInitialized) { return }
    $global:_profileInitialized = $true

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

    foreach ($mod in @('Terminal-Icons', 'ZLocation', 'DockerCompletion')) {
        Import-Module $mod -ErrorAction SilentlyContinue
    }

    . $psdir\modules\helpers\shortcuts.ps1

    foreach ($f in [System.IO.Directory]::GetFiles("$psdir\completions", '*.ps1')) {
        . $f
    }

    $chocoProfile = [System.IO.Path]::Combine($env:ChocolateyInstall, 'helpers\chocolateyProfile.psm1')
    if ([System.IO.File]::Exists($chocoProfile)) {
        Import-Module $chocoProfile
    }

    if (Test-CommandExists starship) {
        try { Invoke-Expression (&starship init powershell) }
        catch { Write-Warning "Error initializing Starship: $_" }
    }
}

$global:_originalPrompt = $null
function global:prompt {
    if (-not $global:_profileInitialized) {
        Initialize-Profile
        $global:_originalPrompt = (Get-Item Function:\prompt -ErrorAction SilentlyContinue).ScriptBlock
    }
    if ($global:_originalPrompt -and $global:_originalPrompt -ne $MyInvocation.ScriptBlock) {
        return & $global:_originalPrompt
    }
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}
