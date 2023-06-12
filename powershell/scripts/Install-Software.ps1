$wingetApps = @(
    "Bccuninstaller",
    "7zip.7zip",
    "Google.PlatformTools",
    "OpenJS.NodeJS.LTS",
    "VideoLAN.VLC",
    "Microsoft.PowerToys",
    "Miniconda3",
    "Gpg4win",
    "Gyan.FFmpeg",
    "sharkdp.fd",
    "junegunn.fzf",
    "Git.Git",
    "voidtools.Everything",
    "AutoHotkey.AutoHotkey",
    "ALCPU.CoreTemp",
    "mIRC.mIRC",
    "qBittorrent.qBittorrent",
    "ShareX.ShareX",
    "youtube-dl.youtube-dl",
    "Calibre.calibre",
    "Starhip.Starship",
    "Piriform.CCleaner",
    "Rufus.Rufus",
    "Microsoft.Sysinternals.ProcessMonitor",
    "Microsoft.Sysinternals.ProcessExplorer"
)

foreach($app in $wingetApps) {
    winget install --id $app
}
