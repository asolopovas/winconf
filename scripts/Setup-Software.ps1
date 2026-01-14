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

foreach($app in $wingetApps) {
    Write-Host "Installing $app"
    winget install --id $app
}
