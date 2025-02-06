$root = Join-Path $env:USERPROFILE 'winconf'
$power_shell_dir = Join-Path $root 'powershell'

. $root\functions.ps1
. $power_shell_dir\completions\git-cli.ps1
. $power_shell_dir\remove-aliases.ps1
. $power_shell_dir\shortcuts.ps1


$starshipConfigPath = Join-Path $power_shell_dir 'starship.toml'
if (Test-Path $starshipConfigPath) {
    $ENV:STARSHIP_CONFIG = $starshipConfigPath
}

$condaHook = Join-Path $env:USERPROFILE 'miniconda3\shell\condabin\conda-hook.ps1'
if (Test-Path $condaHook) {
    try {
        . $condaHook
        conda activate (Join-Path $env:USERPROFILE 'miniconda3')
    }
    catch {
        Write-Verbose "Could not activate conda environment. Error: $($_.Exception.Message)"
    }
}


$moduleName = 'PSReadLine'
if (-not (Get-Module -Name $moduleName -ListAvailable)) {
    Import-Module $moduleName -ErrorAction SilentlyContinue
}

$starshipPs1 = Join-Path $power_shell_dir 'starship.ps1'
if (Test-Path $starshipPs1) {
    . $starshipPs1
}

$ps_major = $PSVersionTable.PSVersion.Major
$ps_minor = $PSVersionTable.PSVersion.Minor

if (($ps_major -gt 7) -or ($ps_major -eq 7 -and $ps_minor -ge 4)) {
    $powerToysModulePath = Join-Path $env:LOCALAPPDATA 'PowerToys\WinGetCommandNotFound.psd1'
    if (Test-Path $powerToysModulePath) {
        try {
            Import-Module $powerToysModulePath
        }
        catch {
            Write-Verbose "Could not import PowerToys CommandNotFound module: $($_.Exception.Message)"
        }
    }
    else {
        Write-Verbose "PowerToys CommandNotFound module not found at: $powerToysModulePath"
    }
}
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}
