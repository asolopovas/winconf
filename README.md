# winconf

Windows dotfiles and provisioning for PowerShell, AutoHotkey v2, Windows Terminal, WSL, AI tools, and dev utilities.

## Install

Run from elevated PowerShell. Re-runs are state-aware.

| Scope | Command |
|---|---|
| Core | `irm asolopovas.github.io/winconf/go\|iex` |
| Core plus apps | `irm asolopovas.github.io/winconf/apps\|iex` |
| Existing clone | `.\init.ps1` |
| Existing clone plus apps | `.\init.ps1 -Software` |

## Includes

- Core tools: PowerShell 7, AutoHotkey v2, Git, fzf, fd, Starship, Everything, PowerToys, VLC, WinSCP.
- Apps: AIMP, CoreTemp, Calibre, GPG4Win, Android tools, FFmpeg, BCUninstaller, Sysinternals, qBittorrent, Rufus, ShareX.
- Shell: profiles, completions, helpers, git/package aliases.
- Desktop: virtual desktops, window movement, app launchers, terminal toggle.
- AI: Claude/OpenCode auth, settings, MCP, skills sync.

## Docs

| Need | Doc |
|---|---|
| Agent map | `AGENTS.md` |
| Harness/rules | `docs/architecture.md` |
| Bootstrap | `docs/bootstrap.md` |
| Shell/modules | `docs/shell-env.md` |
| Tests | `docs/testing.md` |
| AI sync | `docs/ai-sync.md` |
| Hotkeys/aliases | `docs/help.md` |

## Commands

| Task | Command |
|---|---|
| Test | `make test` |
| Sync AI | `.\scripts\sync-ai.ps1` |
| Install/update Codex | `& .\scripts\inst-cdx.ps1` |
| Run installer | `& .\scripts\inst-<name>.ps1` |
| Start AHK | `& .\init-autohotkey.ahk` |

## Local notes

```powershell
Set-LocalUser -Name $env:USERNAME -Password (Read-Host -AsSecureString "New password")
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -PropertyType String -Value "$env:WINDIR\System32\wsl.exe" -Force | Out-Null
Restart-Service sshd
```
