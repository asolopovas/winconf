param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "uninstall", "status")]
    [string]$Action = "install",

    [string]$Token,

    [string]$Rooms,

    [ValidateSet("stable", "nightly")]
    [string]$Channel = "stable",

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$NetdataDir = "$env:ProgramFiles\Netdata Agent"
$MsiUrl = if ($Channel -eq "nightly") {
    "https://github.com/netdata/netdata-nightlies/releases/latest/download/netdata-x64.msi"
} else {
    "https://github.com/netdata/netdata/releases/latest/download/netdata-x64.msi"
}
$TempMsi = Join-Path $env:TEMP "netdata-x64.msi"
$ServiceName = "Netdata"
$FirewallRuleName = "Netdata-Agent-In-TCP"

function Write-Step([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Write-OK([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Skip([string]$Message) {
    Write-Host "  [SKIP] $Message" -ForegroundColor DarkGray
}

function Write-Fail([string]$Message) {
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $Action"
        if ($Token) { $argList += " -Token `"$Token`"" }
        if ($Rooms) { $argList += " -Rooms `"$Rooms`"" }
        if ($Channel -ne "stable") { $argList += " -Channel $Channel" }
        if ($Force) { $argList += " -Force" }
        Write-Step "Relaunching as Administrator..."
        Start-Process pwsh $argList -Verb RunAs
        return $false
    }
    return $true
}

function Invoke-Install {
    if (-not (Assert-Admin)) { return }

    if ((Test-Path $NetdataDir) -and -not $Force) {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Skip "Netdata already installed at $NetdataDir (use -Force to reinstall)"
            Invoke-Status
            return
        }
    }

    if (-not $Token) {
        Write-Fail "Cloud token required. Get yours at https://app.netdata.cloud"
        Write-Host "  Usage: inst-netdata.ps1 -Token <YOUR_TOKEN> -Rooms <YOUR_ROOMS>" -ForegroundColor Yellow
        return
    }

    if (-not $Rooms) {
        Write-Fail "Room ID required. Find it in your Netdata Cloud Space settings."
        Write-Host "  Usage: inst-netdata.ps1 -Token <YOUR_TOKEN> -Rooms <YOUR_ROOMS>" -ForegroundColor Yellow
        return
    }

    Write-Step "Downloading Netdata $Channel MSI"
    $ProgressPreference = "SilentlyContinue"
    try {
        Invoke-WebRequest -Uri $MsiUrl -OutFile $TempMsi -UseBasicParsing
    }
    catch {
        Write-Fail "Download failed: $_"
        return
    }
    if (-not (Test-Path $TempMsi)) {
        Write-Fail "MSI file not found after download"
        return
    }
    $msiSize = (Get-Item $TempMsi).Length / 1MB
    Write-OK ("Downloaded {0:N1} MB to $TempMsi" -f $msiSize)

    Write-Step "Installing Netdata (silent)"
    $msiArgs = @("/qn", "/i", "`"$TempMsi`"", "TOKEN=`"$Token`"", "ROOMS=`"$Rooms`"")
    if ($Force) { $msiArgs += "REINSTALL=ALL" }

    $proc = Start-Process msiexec -ArgumentList $msiArgs -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Fail "MSI installation failed with exit code $($proc.ExitCode)"
        return
    }
    Write-OK "Netdata installed"

    Remove-Item $TempMsi -Force -ErrorAction SilentlyContinue

    Write-Step "Verifying Netdata service"
    Start-Sleep -Seconds 5
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-OK "Netdata service is running"
    }
    elseif ($svc) {
        Write-Step "Starting Netdata service"
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        $svc = Get-Service -Name $ServiceName
        if ($svc.Status -eq "Running") { Write-OK "Service started" }
        else { Write-Fail "Service is $($svc.Status)" }
    }
    else {
        Write-Fail "Netdata service not found after installation"
    }

    if (-not (Get-NetFirewallRule -Name $FirewallRuleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name $FirewallRuleName -DisplayName "Netdata Agent (TCP-In)" `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 19999 | Out-Null
        Write-OK "Firewall rule created for port 19999"
    }
    else {
        Write-Skip "Firewall rule already exists"
    }

    Write-OK "Netdata setup complete"
    Write-Host "  Dashboard: http://localhost:19999" -ForegroundColor DarkGray
    Write-Host "  Cloud:     https://app.netdata.cloud" -ForegroundColor DarkGray
}

function Invoke-Uninstall {
    if (-not (Assert-Admin)) { return }

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc -and -not (Test-Path $NetdataDir)) {
        Write-Skip "Netdata is not installed"
        return
    }

    Write-Step "Uninstalling Netdata"

    $product = Get-CimInstance -ClassName Win32_Product -Filter "Name LIKE '%Netdata%'" -ErrorAction SilentlyContinue
    if ($product) {
        $proc = Start-Process msiexec -ArgumentList "/qn", "/x", $product.IdentifyingNumber -Wait -PassThru
        if ($proc.ExitCode -eq 0) { Write-OK "Netdata uninstalled" }
        else { Write-Fail "Uninstall failed with exit code $($proc.ExitCode)" }
    }
    else {
        Write-Fail "Could not find Netdata MSI product entry"
    }

    if (Get-NetFirewallRule -Name $FirewallRuleName -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -Name $FirewallRuleName
        Write-OK "Firewall rule removed"
    }
}

function Invoke-Status {
    Write-Step "Netdata Status"

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        $color = if ($svc.Status -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  Service: $($svc.Status) (StartupType: $($svc.StartType))" -ForegroundColor $color
    }
    else {
        Write-Fail "Netdata service not found"
        return
    }

    $rule = Get-NetFirewallRule -Name $FirewallRuleName -ErrorAction SilentlyContinue
    if ($rule) {
        Write-Host "  Firewall: Port 19999 allowed" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  Firewall: No rule for port 19999" -ForegroundColor Yellow
    }

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:19999/api/v1/info" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $info = $response.Content | ConvertFrom-Json
            Write-Host "  Version: $($info.version)" -ForegroundColor DarkGray
            Write-Host "  UID: $($info.uid)" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "  API: Not responding (agent may still be starting)" -ForegroundColor Yellow
    }

    Write-Host "  Dashboard: http://localhost:19999" -ForegroundColor DarkGray
    Write-Host "  Cloud:     https://app.netdata.cloud" -ForegroundColor DarkGray
}

switch ($Action) {
    "install"   { Invoke-Install }
    "uninstall" { Invoke-Uninstall }
    "status"    { Invoke-Status }
}
