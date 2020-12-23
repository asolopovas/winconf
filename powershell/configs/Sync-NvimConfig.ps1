$src = "$env:LOCALAPPDATA\nvim"
$target = "$HOME\winconf\dotfiles\.config\nvim"

# Add linux dotfile submodule to winconf
if (-Not (Test-Path "$HOME\winconf\dotfiles")) {
   Push-Location "$HOME\winconf"
   git submodule add git@github.com:asolopovas/dotfiles.git
   Pop-Location
}
# Create config symlink
Sync-Config $src $target

# Install pynvim
choco install microsoft-visual-cpp-build-tools python3 -y | Out-Null
C:\Python39\Scripts\pip3.exe install pynvim | Out-Null

# Create autoload directory
$autoload_dir = "$src\autoload"
if (-Not (Test-Path $autoload_dir)) {
    New-Item $autoload_dir -ItemType Directory -Force
    New-Item $env:LOCALAPPDATA\nvim-plugged -ItemType Directory -Force
    $plugUri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    (
        New-Object Net.WebClient).DownloadFile(
            $plugUri,
            $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            "$autoload_dir\plug.vim"
        )
    )
}

# Create Shell Shortcuts
$nvimQtPath = "C:\tools\neovim\Neovim\bin\nvim-qt.exe"
$regPath = "registry::HKEY_CLASSES_ROOT\Directory\Background\shell"
if (-Not (Test-Path "$regPath\Neovim")) {
    New-Item -Path $regPath -Name "Neovim" -Value "Open in Nvim" | Out-Null
    New-ItemProperty -Path "$regPath\Neovim" -Name "Icon" -Value $nvimQtPath | Out-Null
    New-Item -Path "$regPath\Neovim" -Name "command" -Value "$nvimQtPath `"+cd %V`"" | Out-Null
}

