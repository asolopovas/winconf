# winconf

Personal Windows dotfiles and provisioning for PowerShell, AutoHotkey v2, Windows Terminal, WSL, desktop hotkeys, and dev tools.

## Install

Run from elevated PowerShell.

| Scope | Command |
|---|---|
| Core | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Core plus extended apps | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init-software.ps1 | iex` |
| Existing clone | `.\init.ps1` |
| Existing clone plus extended apps | `.\init.ps1 -Software` |

Re-running is expected; installers check current state first.

## Includes

| Area | Examples |
|---|---|
| Core tools | PowerShell 7, AutoHotkey v2, Git, fzf, fd, Starship, Everything, PowerToys, VLC, WinSCP |
| Extended apps | AIMP, CoreTemp, Calibre, GPG4Win, Android platform tools, FFmpeg, BCUninstaller, Sysinternals, qBittorrent, Rufus, ShareX |
| Shell | profiles, completions, helpers, git/package aliases, Starship |
| Desktop | virtual desktop switching, window movement, app launchers, terminal toggle |
| AI tools | Claude/OpenCode auth, settings, MCP, skills sync |

## Reference

| Need | Doc |
|---|---|
| Agent rules | `AGENTS.md` |
| Repo structure | `docs/architecture.md` |
| Bootstrap contract | `docs/bootstrap.md` |
| Shell/modules | `docs/shell-env.md` |
| Tests | `docs/testing.md` |
| AI sync | `docs/ai-sync.md` |
| Hotkeys/aliases | `docs/help.md` |

## Useful commands

| Task | Command |
|---|---|
| Test | `make test` |
| Sync AI tools | `.\scripts\sync-ai.ps1` |
| Run installer | `& .\scripts\inst-<name>.ps1` |
| Start AHK | `& .\init-autohotkey.ahk` |

## Notes

Set local password for Samba access with a Microsoft account:

```powershell
Set-LocalUser -Name $env:USERNAME -Password (Read-Host -AsSecureString "New password")
```

Set OpenSSH default shell to WSL:

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -PropertyType String -Value "$env:WINDIR\System32\wsl.exe" -Force | Out-Null
Restart-Service sshd
```
