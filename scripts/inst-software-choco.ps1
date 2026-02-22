$chocoApps = @(
    "7zip",
    "bulk-crap-uninstaller",
    "calibre",
    "coretemp",
    "fd",
    "ffmpeg",
    "fzf",
    "gpg4win",
    "miktex",
    "nodejs-lts",
    "platform-tools",
    "powertoys",
    "qbittorrent",
    "rufus",
    "sharex",
    "shellexview",
    "starship",
    "strawberryperl",
    "sysinternals",
    "vlc"
)
foreach ($app in $chocoApps) {
    Write-Host "Installing $app"
    choco install $app -y
}
