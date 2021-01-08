# Setup chocolatey
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | iex

$apps = @(
    "chocolatey-core.extension",
    "chocolatey-windowsupdate.extension",
    # "powershell",
    # Libraries
    # "nodejs.install",
    # "php",
    # "visualstudio2017buildtools",
    "neovim",
    # "golang",
    # "mysql-connector",
    # "openssl.light",
    "git",
    "poshgit",
    "coretemp",
    # "jre8",
    # "mariadb",
    # "composer",
    # "sqlite",
    # Soft
    "7zip",
    "vlc",
    "skype",
    "ccleaner",
    "filezilla",
    "putty",
    "mirc",
    "qbittorrent",
    "spotify",
    "sublimetext3"
    "calibre",
    "fzf",
    # System Soft
    "procexp",
    "procmon",
    "everything",
    "rainmeter",
    "sharex"
)

foreach($app in $apps) {
   choco install -y $app
}

# choco install yarn --ignore-dependencies -y
# yarn global add node-gyp node-sass
# yarn config set msvs_version 2017
