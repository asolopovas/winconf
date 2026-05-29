# winconf

Personal Windows dotfiles and provisioning for PowerShell, AutoHotkey v2, Windows Terminal, WSL, and daily dev tools.

## Install

| Scope | Command |
|---|---|
| Core setup | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Core plus extended apps | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init-software.ps1 | iex` |
| Existing clone | `.\init.ps1` |
| Existing clone plus extended apps | `.\init.ps1 -Software` |

Run from elevated PowerShell. Re-running is expected: installers check existing state before acting.

## Included

| Area | Includes |
|---|---|
| Core tools | PowerShell 7, AutoHotkey v2, Git, fzf, fd, Starship, Everything, PowerToys, VLC, WinSCP |
| Extended apps | AIMP, CoreTemp, Calibre, GPG4Win, Android platform tools, FFmpeg, BCUninstaller, Sysinternals tools, ShellExView, qBittorrent, Rufus, ShareX, Strawberry Perl |
| Shell | PowerShell profile, completions, helpers, git/package aliases, Starship config |
| Desktop | Virtual desktop switching, window movement, app launchers, terminal toggle |
| AI tools | Claude/OpenCode auth, settings, MCP, and skills sync via `scripts/sync-ai.ps1` |

## Common commands

| Task | Command |
|---|---|
| Test | `make test` |
| Load root helpers | `. .\functions.ps1` |
| Reload helpers module | `Import-Module .\powershell\modules\helpers -Force` |
| Sync AI tools | `.\scripts\sync-ai.ps1` |
| Run one installer | `& .\scripts\inst-<name>.ps1` |
| Start AHK | `& .\init-autohotkey.ahk` |

## Hotkeys

| Key | Action |
|---|---|
| `Win+1..9` | Go to desktop |
| `Win+Shift+1..9` | Move active window to desktop |
| `Win+h/j/k/l` | Windows desktop navigation |
| `Win+Enter` | Toggle Ubuntu terminal |
| `RightAlt+Enter` | Toggle PowerShell terminal |
| `Win+Shift+Enter` | New Ubuntu tab |
| `RightAlt+Shift+Enter` | New PowerShell tab |
| `Win+F12` | Activate any Windows Terminal |
| `Win+c` | Browser |
| `Win+b` | Firefox |
| `Win+x` | Directory Opus |
| `Win+m` | AIMP |
| `Win+f` | Maximize/restore |
| `Win+q` | Close active window |

More: `docs/help.md`.

## Docs

| Doc | Purpose |
|---|---|
| `AGENTS.md` | Agent map and repo-wide constraints |
| `docs/architecture.md` | Repo layers and dependency rules |
| `docs/bootstrap.md` | Bootstrap and installer contract |
| `docs/shell-env.md` | Profile, modules, aliases, manifests |
| `docs/testing.md` | Pester suites and validation rules |
| `docs/ai-sync.md` | Claude/OpenCode sync contract |
| `docs/help.md` | Hotkeys and daily reference |

## Notes

Set local password for Samba access with a Microsoft account:

```powershell
Set-LocalUser -Name $env:USERNAME -Password (Read-Host -AsSecureString "New password")
```

Set the OpenSSH default shell to WSL:

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -PropertyType String -Value "$env:WINDIR\System32\wsl.exe" -Force | Out-Null
Restart-Service sshd
```
