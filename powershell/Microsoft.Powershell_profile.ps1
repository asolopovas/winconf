$root = Join-Path $env:USERPROFILE 'winconf'
$psdir = Join-Path $root 'powershell'

. $root\functions.ps1
. $psdir\completions\git-cli.ps1
. $psdir\modules\aliases\remove-aliases.ps1
. $psdir\modules\helpers\shortcuts.ps1

$ENV:STARSHIP_CONFIG = Join-Path $psdir 'configs\starship.toml'
$condaHook = Join-Path $env:USERPROFILE 'miniconda3\shell\condabin\conda-hook.ps1'
if (Test-Path $condaHook) {
    try { . $condaHook; conda activate base 2>$null } catch { }
}

$Host.UI.RawUI.WindowTitle = "PowerShell"
try { $null = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

if (Test-CommandExists starship) {
    try { Invoke-Expression (&starship init powershell) } catch {}
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
