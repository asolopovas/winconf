# AGENTS.md - Coding Agent Guidelines for winconf

## Project Overview

Windows dotfiles and development environment bootstrap repository. Automated
provisioning of a Windows dev machine using PowerShell, AutoHotkey v2, and Lua.
All scripts are **idempotent** (safe to re-run). There is no traditional build
system, package.json, or compiled output.

**Author:** Andrius Solopovas  
**Canonical path:** `$env:USERPROFILE\winconf`  
**Entry point:** `init.ps1`

## Languages

| Language    | Usage                                  | Share |
|-------------|----------------------------------------|-------|
| PowerShell  | Profile, modules, setup/provisioning   | ~70%  |
| AutoHotkey v2 | Hotkeys, window management, terminal | ~25%  |
| JSON/TOML   | Terminal profiles, Starship config     | Minor |

## Build / Run / Test Commands

There is no build step or test suite. The "build" is the bootstrap process.

Full bootstrap (run as admin):
```powershell
.\init.ps1
```

Bootstrap with extended software:
```powershell
.\init.ps1 -Software
```

Remote bootstrap:
```powershell
iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex
```

Load shared utility functions in a session:
```powershell
. .\functions.ps1
```

Run a single setup script:
```powershell
& .\scripts\Setup-SSH.ps1
& .\scripts\Setup-Powershell.ps1
```

Reload PowerShell modules after changes:
```powershell
Import-Module .\powershell\modules\helpers -Force
Import-Module .\powershell\modules\aliases -Force
```

Update module manifest after adding/removing functions:
```powershell
UpdateModuleManifest -moduleManifestPath .\powershell\modules\helpers\helpers.psd1
```

There is **no linter, formatter, or test framework** configured. No PSScriptAnalyzer,
Pester, .editorconfig, or formatting config exists.

## Directory Structure

| Path                        | Description                                   |
|-----------------------------|-----------------------------------------------|
| `init.ps1`                  | Main bootstrap entry point                    |
| `functions.ps1`             | Shared PS utilities (symlinks, permissions)   |
| `init-autohotkey.ahk`       | AHK v2 entry point, includes all AHK modules |
| `autohotkey/`               | AHK v2 modules (hotkeys, window mgmt, terminal) |
| `powershell/`               | PS profile, completions, configs              |
| `powershell/modules/aliases/` | PS module: global aliases (git, docker, etc.) |
| `powershell/modules/helpers/` | PS module: 83+ exported utility functions    |
| `scripts/`                  | Setup-*.ps1 provisioning scripts (run by init.ps1) |
| `configs/`                  | Registry files                                |
| `terminal/`                 | Windows Terminal profiles.json                |
| `bin/`                      | User binaries (on PATH)                       |
| `tmp/`                      | Scratch scripts (gitignored)                  |

## Code Style - General

- **Do NOT add comments in code.** This codebase does not use inline comments,
  block comments, or explanatory comments. Code should be self-documenting through
  clear naming. This applies to all languages: PowerShell, AutoHotkey, and Lua.

## Code Style - PowerShell

### Naming

- **Exported functions:** PascalCase `Verb-Noun` per PowerShell convention:
  `Test-CommandExists`, `Add-DefenderExclusion`, `Find-LockingProcess`
- **Short alias functions:** lowercase abbreviated: `gs`, `gc`, `gp`, `gl`, `gk`
- **Internal/helper functions:** either PascalCase without dash (`SetPermissions`,
  `CreateSymLink`, `SourceFile`) or camelCase (`buildWebConfig`, `sshCopyID`)
- **Variables:** camelCase preferred (`$displayName`, `$targetValue`, `$modulePath`)
- **Constants/config:** UPPER_SNAKE (`$DOTFILES`, `$SCRIPTS_DIR`, `$REPO_URL`)

### Parameters

- Use `param()` blocks at function top
- Mark required params: `[Parameter(Mandatory = $true)]` or `[Parameter(Mandatory)]`
- Use type annotations: `[string]`, `[int]`, `[switch]`, `[string[]]`
- Validate with `[ValidateSet()]` where applicable
- Use splatting (`@params`) for complex cmdlet calls

### Error Handling

- Use `try/catch` with `Write-Error`, `Write-Warning`, or colored `Write-Host`
- `-ErrorAction SilentlyContinue` for "try and ignore" patterns
- Set `$ErrorActionPreference = "Stop"` in critical scripts
- Check `$LASTEXITCODE` after external commands (git, wsl, winget)
- Guard file operations with `Test-Path` before access

### Console Output

- Color-coded via `Write-Host -ForegroundColor`:
  - **Cyan/DarkCyan** = informational steps
  - **Green** = success
  - **Yellow** = warnings
  - **Red** = errors
  - **DarkGray** = details/verbose
- Some scripts define helpers: `Write-Step`, `Write-OK`, `Write-Skip`, `Write-Fail`
- Use `Start-Transcript` for session logging in bootstrap scripts

### Module System

- Compose modules via dot-sourcing: `. $PSScriptRoot\file.ps1`
- Module manifests (`.psd1`) explicitly list `FunctionsToExport` and `AliasesToExport`
- After adding a function, update the manifest's `FunctionsToExport` array
- Remove built-in alias conflicts via `Remove-Item -Force Alias:$alias`

### Path Handling

- Use `Join-Path` for path construction
- Use `$env:USERPROFILE\winconf` as canonical root
- `Test-Path` before file/directory operations

## Code Style - AutoHotkey v2

### File Header

Every `.ahk` file must start with:
```autohotkey
#Requires AutoHotkey v2.0
```

### Naming

- **Functions:** PascalCase: `ToggleTerminal`, `RunOrActivate`, `CenterWindow`,
  `CycleWindowsWithinSameClass`, `MoveCurrentWindowToDesktop`
- **Variables:** camelCase: `currentToggleId`, `defaultBrowserPath`, `windowID`
- **Global state:** declared with `global` keyword: `global targetWindows := Map()`

### Patterns

- Hotkey modifiers: `#` = Win, `!` = Alt, `+` = Shift, `^` = Ctrl
- Use `try/catch` around window operations (windows can disappear)
- String concatenation with dot: `"text" . variable`
- Includes use quotes: `#Include "debug.ahk"`
- DLL interop via `DllCall` for Windows API (virtual desktop accessor)
- Timer-based polling: `SetTimer(callback, interval)`

### Window Management

- Identify windows with `ahk_exe`, `ahk_class`, `ahk_id` selectors
- Track window handles in global `Map()` objects
- Always check `WinExist()` before `WinActivate()` operations
- Use `WinWaitActive` with timeout after launching processes

## Git Conventions

- **Commit messages:** short, lowercase, imperative mood
- Examples: `add WinSCP to essential software`, `fix pwsh profile loading`,
  `update readme`, `remove claude.md`
- Prefix with action verb: `add`, `fix`, `update`, `remove`, `save`
- No conventional commits (no `feat:`, `fix:` prefixes)
- No PR/branch workflow — direct commits to `main`

## Key Design Principles

1. **Idempotent scripts** — every script must be safe to re-run without side effects
2. **Guard before act** — always `Test-Path`, `Test-CommandExists`, or check registry
   before creating/modifying resources
3. **Fail gracefully** — warn and continue rather than hard-fail, except for critical
   dependencies (git clone failure → `exit 1`)
4. **winget-first** — use winget for software installation; Chocolatey is secondary
5. **Symlink configs** — link configs from the repo rather than copying them
6. **Non-elevated when possible** — use `RunAsUser` in AHK, elevate only when needed

## Important Notes for Agents

- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` exist
- The `tmp/` directory is gitignored scratch space — do not commit files there
- When adding new PowerShell helper functions, update the corresponding `.psd1`
  manifest's `FunctionsToExport` array
- AHK scripts auto-reload on save when editing in VS Code (via `~^s` hotkey handler)
- The `init-autohotkey.ahk` is the AHK entry point and includes all AHK modules
- PowerShell modules are loaded from `$env:USERPROFILE\winconf\powershell\modules`
