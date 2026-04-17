$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  compact-wsl.ps1 must be run as Administrator (diskpart requires elevation)" -ForegroundColor Red
    return
}

$prevEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode

try {
    $distros = (wsl --list --quiet 2>$null) | Where-Object { $_ -and $_.Trim() }
    if (-not $distros) {
        Write-Host "  No WSL distributions found" -ForegroundColor Yellow
        return
    }

    $running = (wsl --list --verbose 2>$null) |
        Select-Object -Skip 1 |
        Where-Object { $_ -match 'Running' }

    if ($running) {
        Write-Host "  Shutting down WSL..." -ForegroundColor DarkGray
        wsl --shutdown
        Start-Sleep -Seconds 3
    }
} finally {
    [Console]::OutputEncoding = $prevEncoding
}

$searchPaths = @(
    "$env:LOCALAPPDATA\Packages",
    "$env:LOCALAPPDATA\Docker"
)

$vhdxFiles = @()
foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        $found = Get-ChildItem -Path $searchPath -Filter "ext4.vhdx" -Recurse -ErrorAction SilentlyContinue
        $vhdxFiles += $found
    }
}

if (-not $vhdxFiles) {
    Write-Host "  No ext4.vhdx files found" -ForegroundColor Yellow
    return
}

foreach ($vhdx in $vhdxFiles) {
    $sizeBefore = [math]::Round($vhdx.Length / 1GB, 2)
    $relativePath = $vhdx.FullName.Replace($env:LOCALAPPDATA, '%LOCALAPPDATA%')
    Write-Host "  Compacting $relativePath ($sizeBefore GB)..." -ForegroundColor DarkGray

    $diskpartScript = New-TemporaryFile
    @(
        "select vdisk file=`"$($vhdx.FullName)`""
        "attach vdisk readonly"
        "compact vdisk"
        "detach vdisk"
        "exit"
    ) | Set-Content -Path $diskpartScript.FullName

    $process = Start-Process -FilePath "diskpart" -ArgumentList "/s `"$($diskpartScript.FullName)`"" -Wait -PassThru -NoNewWindow
    Remove-Item $diskpartScript.FullName -ErrorAction SilentlyContinue

    if ($process.ExitCode -ne 0) {
        Write-Host "  Failed to compact $relativePath (exit code $($process.ExitCode))" -ForegroundColor Red
        continue
    }

    $vhdx.Refresh()
    $sizeAfter = [math]::Round($vhdx.Length / 1GB, 2)
    $saved = [math]::Round($sizeBefore - $sizeAfter, 2)

    if ($saved -gt 0) {
        Write-Host "  Compacted ${relativePath}: $sizeBefore GB -> $sizeAfter GB (saved $saved GB)" -ForegroundColor Green
    } else {
        Write-Host "  $relativePath already optimal ($sizeAfter GB)" -ForegroundColor DarkGray
    }
}
