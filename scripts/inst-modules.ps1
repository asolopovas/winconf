param([switch]$Update)

$modules = @(
    'posh-git'
    'Terminal-Icons'
    'ZLocation'
    'DockerCompletion'
    'PSFzf'
)

$useResourceGet = [bool](Get-Command Install-PSResource -ErrorAction SilentlyContinue)

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
            Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber -AcceptLicense -ErrorAction Stop
        }
        $new = Get-Module -Name $mod -ListAvailable | Select-Object -First 1
        Write-Host "  $mod $($new.Version) installed" -ForegroundColor Green
    }
}
