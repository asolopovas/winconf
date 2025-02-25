$wingetApps = @(
    "7zip.7zip",
    "ALCPU.CoreTemp",
    "Anaconda.Miniconda3",
    "AutoHotkey.AutoHotkey",
    "Calibre.calibre",
    "GnuPG.Gpg4win",
    "Google.PlatformTools",
    "Gyan.FFmpeg",
    "junegunn.fzf",
    "Klocman.BulkCrapUninstaller",
    "Microsoft.PowerToys",
    "Microsoft.Sysinternals.ProcessExplorer",
    "Microsoft.Sysinternals.ProcessMonitor",
    "NirSoft.ShellExView",
    "qBittorrent.qBittorrent",
    "Rufus.Rufus",
    "ShareX.ShareX",
    "sharkdp.fd",
    "Starship.Starship",
    "StrawberryPerl.StrawberryPerl",
    "VideoLAN.VLC"
)

foreach($app in $wingetApps) {
    Write-Host "Installing $app"
    winget install --id $app
}
