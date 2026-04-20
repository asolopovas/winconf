param([switch]$Update)

$modules = @(
    'posh-git'
    'Terminal-Icons'
    'ZLocation'
    'DockerCompletion'
    'PSFzf'
)

$useResourceGet = [bool](Get-Command Install-PSResource -ErrorAction SilentlyContinue)

if (-not $useResourceGet) {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "  Bootstrapping NuGet provider..." -ForegroundColor DarkGray
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    $pg = (Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    if (-not $pg -or $pg -lt [version]'2.0.0') {
        Write-Host "  Updating PowerShellGet (found $pg)..." -ForegroundColor DarkGray
        Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser -SkipPublisherCheck -WarningAction SilentlyContinue
        Import-Module PowerShellGet -Force
    }
}

$installParams = @{ Scope = 'CurrentUser'; Force = $true; AllowClobber = $true; ErrorAction = 'Stop' }
if ((Get-Command Install-Module).Parameters.ContainsKey('AcceptLicense')) {
    $installParams['AcceptLicense'] = $true
}

foreach ($mod in $modules) {
    $installed = Get-Module -Name $mod -ListAvailable -ErrorAction SilentlyContinue
    if ($installed) {
        if ($Update) {
            Write-Host "  Updating $mod..." -ForegroundColor DarkGray
            try {
                if ($useResourceGet) {
                    Update-PSResource -Name $mod -ErrorAction SilentlyContinue
                } else {
                    Update-Module -Name $mod -Force -ErrorAction SilentlyContinue
                }
            } catch {}
            $updated = Get-Module -Name $mod -ListAvailable | Select-Object -First 1
            Write-Host "  $mod $($updated.Version)" -ForegroundColor Green
        } else {
            Write-Host "  $mod $($installed[0].Version) already installed" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  Installing $mod..." -ForegroundColor Cyan
        if ($useResourceGet) {
            Install-PSResource -Name $mod -Scope CurrentUser -TrustRepository -AcceptLicense -ErrorAction Stop
        } else {
            Install-Module -Name $mod @installParams
        }
        $new = Get-Module -Name $mod -ListAvailable | Select-Object -First 1
        Write-Host "  $mod $($new.Version) installed" -ForegroundColor Green
    }
}
