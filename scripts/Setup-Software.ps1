$wingetApps = @(
    "AutoHotkey.AutoHotkey",
    "Klocman.BulkCrapUninstaller",
    "7zip.7zip",
    "Google.PlatformTools",
    "VideoLAN.VLC",
    "Microsoft.PowerToys",
    "Anaconda.Miniconda3",
    "StrawberryPerl.StrawberryPerl",
    "GnuPG.Gpg4win",
    "NirSoft.ShellExView",
    "Gyan.FFmpeg",
    "sharkdp.fd",
    "junegunn.fzf",
    "Twilio.Authy",
    "ALCPU.CoreTemp",
    "mIRC.mIRC",
    "qBittorrent.qBittorrent",
    "ShareX.ShareX",
    "Calibre.calibre",
    "Starship.Starship",
    "MiKTeX.MiKTeX",
    "Rufus.Rufus",
    "Microsoft.Sysinternals.ProcessMonitor",
    "Microsoft.Sysinternals.ProcessExplorer",
    "NirSoft.ShellExView"
)


foreach($app in $wingetApps) {
    Write-Host "Installing $app"
    winget install --id $app
}
