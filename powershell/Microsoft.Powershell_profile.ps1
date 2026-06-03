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


function global:z {
    Remove-Item Function:z -ErrorAction SilentlyContinue
    Import-Module ZLocation -ErrorAction SilentlyContinue
    z @args
}

function global:l {
    Remove-Item Function:l -ErrorAction SilentlyContinue
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    Get-ChildItem @args
}

function global:ls {
    Remove-Item Function:ls -ErrorAction SilentlyContinue
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    Get-ChildItem @args
}

Remove-Item Alias:l, Alias:ls -ErrorAction SilentlyContinue

Register-ArgumentCompleter -Native -CommandName 'docker', 'docker.exe' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    Import-Module DockerCompletion -ErrorAction SilentlyContinue
    [System.Management.Automation.CommandCompletion]::CompleteInput(
        $commandAst.Extent.Text, $cursorPosition, $null
    ).CompletionMatches
}

function global:refreshenv {
    Remove-Item Function:refreshenv -ErrorAction SilentlyContinue
    $cp = [System.IO.Path]::Combine($env:ChocolateyInstall, 'helpers\chocolateyProfile.psm1')
    if ([System.IO.File]::Exists($cp)) { Import-Module $cp; refreshenv @args }
}

$global:_profileInitialized = $false
function global:Initialize-Profile {
    if ($global:_profileInitialized) { return }
    $global:_profileInitialized = $true

    try {
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineOption -BellStyle None
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

    . $psdir\modules\helpers\shortcuts.ps1

    foreach ($f in [System.IO.Directory]::GetFiles("$psdir\completions", '*.ps1')) {
        . $f
    }

    if (Test-CommandExists starship) {
        try {
            $cacheDir = Join-Path $env:LOCALAPPDATA 'winconf'
            if (-not [System.IO.Directory]::Exists($cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            $cachePath = Join-Path $cacheDir 'starship-init.ps1'
            $exePath = (Get-Command starship).Source
            $needsRefresh = $true
            if ([System.IO.File]::Exists($cachePath)) {
                $cacheTime = (Get-Item $cachePath).LastWriteTime
                $exeTime   = (Get-Item $exePath).LastWriteTime
                $cfgTime   = if (Test-Path $env:STARSHIP_CONFIG) { (Get-Item $env:STARSHIP_CONFIG).LastWriteTime } else { [datetime]::MinValue }
                if ($cacheTime -gt $exeTime -and $cacheTime -gt $cfgTime) { $needsRefresh = $false }
            }
            if ($needsRefresh) {
                & starship init powershell --print-full-init | Set-Content -Path $cachePath -Encoding utf8
            }
            . $cachePath
        } catch { Write-Warning "Error initializing Starship: $_" }
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
