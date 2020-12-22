$confSrc = "$env:LOCALAPPDATA\nvim"
$confTarget = "$PSScriptRoot\..\..\..\dotfiles\.config\nvim"
$autoload_dir = "$confSrc\autoload"
choco install microsoft-visual-cpp-build-tools python3 -y
C:\Python38\Scripts\pip3.exe install pynvim
New-Item $autoload_dir -ItemType Directory -Force
New-Item $env:LOCALAPPDATA\nvim-plugged -ItemType Directory -Force
$uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
(New-Object Net.WebClient).DownloadFile(
  $uri,
  $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
    "$autoload_dir\plug.vim"
  )
)
$nvimQtPath = "C:\tools\neovim\Neovim\bin\nvim-qt.exe"
New-Item -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ -Name "Neovim" -Value "Open in Nvim" | Out-Null
New-ItemProperty -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Neovim\ -Name "Icon" -Value $nvimQtPath | Out-Null
New-Item -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Neovim\ -Name "command" -Value "$nvimQtPath `"+cd %V`"" | Out-Null

Sync-Config $confSrc $confTarget
