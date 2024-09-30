$chocoApps = @(
    "bulk-crap-uninstaller",
    "7zip",
    "platform-tools",
    "nodejs-lts",
    "vlc",
    "powertoys",
    "miniconda3",
    "strawberryperl",
    "gpg4win",
    "shellexview",
    "ffmpeg",
    "fd",
    "fzf",
    "authy",
    "coretemp",
    "mirc",
    "qbittorrent",
    "sharex",
    "youtube-dl",
    "calibre",
    "starship",
    "miktex",
    "rufus",
    "sysinternals",
    "spotify"
)

foreach ($app in $chocoApps) {
    Write-Host "Installing $app"
    choco install $app -y
}
