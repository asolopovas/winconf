# winconf Help                                    AHK v2 | winconf

## Virtual Desktops (AHK)

```
 Key             │ Action                Key             │ Action
 ────────────────┼────────────────────   ────────────────┼────────────────────
 Win+1..9        │ Go to desktop         Win+Shift+1..9  │ Move win to desktop
 Win+h/j/k/l     │ Win+Arrow nav         LWin+./,        │ AltTab / Shift-AltTab
```

## Windows & Apps (AHK)

```
 Key             │ Action                Key             │ Action
 ────────────────┼────────────────────   ────────────────┼────────────────────
 Win+f           │ Toggle maximize       Win+q           │ Close window
 Win+c           │ Default browser       Win+b           │ Firefox
 Win+x           │ Directory Opus        Win+Shift+x     │ Opus (elevated)
 Win+m           │ AIMP                  F7              │ AIMP delete & skip
 Alt+, / Alt+.   │ Cycle same-class      Alt+Shift+F11   │ Restart Explorer
 Alt+F8          │ Reload AHK            ~Ctrl+S         │ Auto-reload on save
 Alt+F9          │ Copy active ahk_id    Win+F9          │ Activate by ahk_id
 Ctrl+Shift+F12  │ Toggle Defender       Win+Ctrl+S      │ Terminal status
```

## Terminal toggle

```
 Key             │ Action
 ────────────────┼────────────────────
 (see terminal.ahk for bound keys — quake-style Windows Terminal)
```

## Git aliases (PowerShell)

```
 Alias           │ Action                Alias           │ Action
 ────────────────┼────────────────────   ────────────────┼────────────────────
 gs              │ git status            gb              │ git branch
 gc <msg>        │ git add -A + commit   ga              │ git commit --amend
 gd              │ git diff              gg              │ git log
 gk <branch>     │ git checkout          gt              │ git tag
 gp / gpo / gpf  │ push / origin / force gl              │ git pull
 gsclone <r>     │ clone git@...         ghclone <r>     │ clone https://...
 gundo           │ reset --hard HEAD~1   nah             │ hard reset + clean
 gw              │ add -A + prompt msg   bfg <args>      │ BFG repo cleaner
```

## Bootstrap

```
 Command                          │ Action
 ─────────────────────────────────┼──────────────────────────────
 .\init.ps1                       │ Fresh install or update
 .\init.ps1 -Software             │ Also install extended software
 .\scripts\sync-ai.ps1            │ Sync Claude/OpenCode auth+skills+MCP
 .\scripts\inst-<name>.ps1        │ Run a single installer
 make test                        │ Run Pester suite
 Import-Module ... -Force         │ Reload a module after edits
```

## Module system

```
 Path                                            │ Purpose
 ────────────────────────────────────────────────┼──────────────────────────
 powershell/modules/helpers/                     │ Exported utilities
 powershell/modules/aliases/                     │ Global + git aliases
 functions.ps1                                   │ Root shared helpers
 autohotkey/                                     │ AHK v2 modules
 init-autohotkey.ahk                             │ AHK entry point
```
