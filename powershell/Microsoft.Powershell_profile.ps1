# PowerShell Profile - Windows Configuration
$root = Join-Path $env:USERPROFILE 'winconf'
$psdir = Join-Path $root 'powershell'

# Source core functions with error handling
try {
    . $root\functions.ps1
    . $psdir\completions\git-cli.ps1
    . $psdir\modules\aliases\remove-aliases.ps1
    Import-Module $psdir\modules\aliases
    . $psdir\modules\helpers\shortcuts.ps1
} catch {
    Write-Warning "Error loading PowerShell modules: $_"
}

# Configure Starship prompt
$ENV:STARSHIP_CONFIG = Join-Path $psdir 'configs\starship.toml'

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

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

$pageantPaths = @(
    "$env:LOCALAPPDATA\Programs\WinSCP\PuTTY\pageant.exe"
    "$env:ProgramFiles\PuTTY\pageant.exe"
    "$env:ProgramFiles(x86)\PuTTY\pageant.exe"
)
$pageant = $pageantPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($pageant -and !(Get-Process pageant -ErrorAction SilentlyContinue)) {
    $ppkFiles = Get-ChildItem "$env:USERPROFILE\.ssh\*.ppk" -ErrorAction SilentlyContinue
    if ($ppkFiles) {
        Start-Process $pageant -ArgumentList ($ppkFiles.FullName)
    }
}
