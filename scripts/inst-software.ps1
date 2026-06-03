$ErrorActionPreference = "Stop"

$wingetApps = @(
    "AIMP.AIMP"
    "ALCPU.CoreTemp"
    "Calibre.calibre"
    "GnuPG.Gpg4win"
    "Google.PlatformTools"
    "Gyan.FFmpeg"
    "Klocman.BulkCrapUninstaller"
    "Microsoft.Sysinternals.ProcessExplorer"
    "Microsoft.Sysinternals.ProcessMonitor"
    "NirSoft.ShellExView"
    "qBittorrent.qBittorrent"
    "Rufus.Rufus"
    "ShareX.ShareX"
    "StrawberryPerl.StrawberryPerl"
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget required" }

foreach ($app in $wingetApps) {
    winget list --id $app --exact --accept-source-agreements 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  $app already installed" -ForegroundColor DarkGray
        continue
    }

    Write-Host "  Installing $app" -ForegroundColor Cyan
    winget install --id $app --exact --silent --disable-interactivity --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "Failed to install $app" }
}
