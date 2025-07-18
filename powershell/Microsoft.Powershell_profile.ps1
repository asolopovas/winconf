# PowerShell Profile - Windows Configuration
$root = Join-Path $env:USERPROFILE 'winconf'
$psdir = Join-Path $root 'powershell'

# Source core functions with error handling
try {
    . $root\functions.ps1
    . $psdir\completions\git-cli.ps1
    . $psdir\modules\aliases\remove-aliases.ps1
    . $psdir\modules\helpers\shortcuts.ps1
} catch {
    Write-Warning "Error loading PowerShell modules: $_"
}

# Configure Starship prompt
$ENV:STARSHIP_CONFIG = Join-Path $psdir 'configs\starship.toml'

# Conda initialization
$condaHook = Join-Path $env:USERPROFILE 'miniconda3\shell\condabin\conda-hook.ps1'
if (Test-Path $condaHook) {
    try { . $condaHook; conda activate base 2>$null } catch { }
}

# Configure console
$Host.UI.RawUI.WindowTitle = "PowerShell"
try { $null = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# Initialize Starship prompt
if (Test-CommandExists starship) {
    try { 
        Invoke-Expression (&starship init powershell)
    } catch {
        Write-Warning "Error initializing Starship: $_"
    }
} else {
    Write-Warning "Starship not found in PATH. Please ensure it's installed and in your PATH."
}

# PowerToys integration
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $ptPath = Join-Path $env:LOCALAPPDATA 'PowerToys\WinGetCommandNotFound.psd1'
    if (Test-Path $ptPath) {
        try { Import-Module $ptPath } catch {}
    }
}

# FNM Node.js version manager
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
