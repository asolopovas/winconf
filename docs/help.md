# Help

## Bootstrap

| Command | Action |
|---|---|
| `.\init.ps1` | Fresh install or update |
| `.\init.ps1 -Software` | Include extended apps |
| `.\scripts\inst-<name>.ps1` | Run one installer |
| `.\scripts\sync-ai.ps1` | Sync Claude/OpenCode auth, settings, MCP, skills |
| `make test` | Run Pester suite |
| `Import-Module .\powershell\modules\helpers -Force` | Reload helpers module |

## Virtual desktops

| Key | Action |
|---|---|
| `Win+1..9` | Go to desktop |
| `Win+Shift+1..9` | Move active window to desktop |
| `Win+h/j/k/l` | Windows desktop navigation |
| `LeftWin+.` | AltTab |
| `LeftWin+,` | ShiftAltTab |

## Windows and apps

| Key | Action |
|---|---|
| `Win+f` | Maximize/restore |
| `Win+q` | Close active window |
| `Win+c` | Default browser |
| `Win+b` | Firefox |
| `Win+x` | Directory Opus |
| `Win+Shift+x` | Directory Opus elevated |
| `Win+m` | AIMP |
| `F7` | AIMP delete current and skip |
| `Alt+.` / `Alt+,` | Cycle same-class windows |
| `Alt+Shift+F11` | Restart Explorer |
| `Alt+F8` | Reload AHK |
| `Alt+F9` | Copy active `ahk_id` |
| `Win+F9` | Activate by `ahk_id` |
| `Ctrl+Shift+F12` | Toggle Defender |
| `Win+Ctrl+s` | Terminal status |

## Terminal

| Key | Action |
|---|---|
| `Win+Enter` | Toggle Ubuntu terminal |
| `RightAlt+Enter` | Toggle PowerShell terminal |
| `Win+Shift+Enter` | New Ubuntu tab |
| `RightAlt+Shift+Enter` | New PowerShell tab |
| `Win+F12` | Activate any Windows Terminal |

## Git aliases

| Alias | Action |
|---|---|
| `gs` | `git status` |
| `gb` | `git branch` |
| `gc <msg>` | add all and commit |
| `ga` | amend commit |
| `gd` | `git diff` |
| `gg` | `git log` |
| `gk <branch>` | checkout branch |
| `gt` | `git tag` |
| `gp` | push |
| `gpo` | push origin |
| `gpf` | force push |
| `gl` | pull |
| `gsclone <repo>` | clone `git@github.com:asolopovas/<repo>` |
| `ghclone <repo>` | clone `https://github.com/asolopovas/<repo>` |
| `gundo` | hard reset to previous commit |
| `nah` | hard reset and clean |
| `gw` | add all and prompt for commit message |
| `bfg <args>` | run BFG, downloading jar if missing |

## Paths

| Path | Purpose |
|---|---|
| `functions.ps1` | root setup helpers |
| `powershell/modules/helpers/` | exported utilities |
| `powershell/modules/aliases/` | global aliases |
| `autohotkey/` | AHK v2 modules |
| `init-autohotkey.ahk` | AHK entry point |
