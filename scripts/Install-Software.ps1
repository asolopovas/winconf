$wingetApps = @(
    "AutoHotkey.AutoHotkey",
    "Klocman.BulkCrapUninstaller",
    "7zip.7zip",
    "Google.PlatformTools",
    "OpenJS.NodeJS.LTS",
    "VideoLAN.VLC",
    "Microsoft.PowerToys",
    "Anaconda.Miniconda3",
    "StrawberryPerl.StrawberryPerl",
    "GnuPG.Gpg4win",
    "NirSoft.ShellExView",
    "Gyan.FFmpeg",
    "sharkdp.fd",
    "junegunn.fzf",
    "Git.Git",
    "voidtools.Everything",
    "Twilio.Authy",
    "ALCPU.CoreTemp",
    "mIRC.mIRC",
    "qBittorrent.qBittorrent",
    "ShareX.ShareX",
    "youtube-dl.youtube-dl",
    "Calibre.calibre",
    "Starship.Starship",
    "MiKTeX.MiKTeX",
    "Rufus.Rufus",
    "Microsoft.Sysinternals.ProcessMonitor",
    "Microsoft.Sysinternals.ProcessExplorer"
)


foreach($app in $wingetApps) {
    Write-Host "Installing $app"
    winget install --id $app
}
