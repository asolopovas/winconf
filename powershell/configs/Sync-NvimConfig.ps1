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
Copy-Item C:\Python39\python.exe C:\Python39\python3.exe
Remove-Item  C:\Users\Andrius\AppData\Local\Microsoft\WindowsApps\python3.exe -ErrorAction SilentlyContinue

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
$exe = "C:\tools\neovim\Neovim\bin\nvim-qt.exe"
Add-ShellContext "Nvim" $exe "file"
