# Windows Dotfiles

Automated Windows development environment with PowerShell, AutoHotkey v2, and modern tooling.

## Quick Start

```powershell
# Basic setup
iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex

# With additional software
iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init-software.ps1 | iex
```

## What's Included

**Core Tools:** PowerShell 7, WezTerm, AutoHotkey v2, Git, fzf, Starship, Everything, PowerToys, VLC

**Extended Software:** CoreTemp, Miniconda, Calibre, GPG4Win, FFmpeg, Sysinternals, qBittorrent, ShareX, Rufus

## Key Features

- **Virtual Desktop Management** - Win+1-9 switching with vim-style navigation
- **Application Launchers** - Quick access to development tools
- **Enhanced Git Workflow** - Custom aliases and PowerShell integration
- **Terminal Automation** - WezTerm with Ubuntu WSL integration
- **Window Management** - Vim-style controls and smart navigation

## Hotkeys

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `Win+1-9` | Switch desktop | `Win+Shift+1-9` | Move window to desktop |
| `Win+H/J/K/L` | Navigate desktops | `Win+Enter` | Toggle Ubuntu terminal |
| `Win+Shift+Enter` | New Ubuntu terminal | `Win+F12` | Admin terminal |
| `Win+C` | Browser | `Win+M` | Music player |
| `Win+F` | Maximize/restore | `Win+Q` | Close window |

## PowerShell Aliases

```powershell
# Git shortcuts
gs          # git status
gc "msg"    # git add . && git commit -m "msg"
gp          # git push
gl          # git pull
gk branch   # git checkout branch

# System
which cmd   # Get-Command
l           # ls with colors
dk          # docker
```

## Development

```powershell
. .\functions.ps1                    # Load utilities
Test-CommandExists git              # Check if command exists
```

All scripts are idempotent and safe to re-run.

# Notes

*Set password for samba user with microsoft account:*
```
Set-LocalUser -Name $env:username -Password (Read-Host -AsSecureString "New password")
```

*OpenSSH change default sheel*
```powershell
New-ItemProperty `
  -Path "HKLM:\SOFTWARE\OpenSSH" `
  -Name "DefaultShell" `
  -PropertyType String `
  -Value "$env:WINDIR\System32\wsl.exe" `
  -Force | Out-Null

# Restart sshd so it picks it up
Restart-Service sshd
```
