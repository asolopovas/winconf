---
name: winconf
description: Coding agent guide for the Windows dotfiles / dev bootstrap repo
---

# AGENTS Guide for winconf

Personal Windows dotfiles and provisioning. PowerShell + AutoHotkey v2 + a little Lua. Bootstraps a dev machine via `init.ps1`. All scripts are idempotent. Canonical path: `$env:USERPROFILE\winconf`. Follow unless the user gives explicit overrides.

## Hard Constraints

- **NO COMMENTS in any file.** No descriptive, explanatory, or section-divider comments — ever, in any language (PowerShell, AHK, Lua, JSON). Only allowed: shebangs, `#Requires` directives, and pragmas the interpreter actually reads. If the WHY is genuinely non-obvious (workaround, hidden constraint), ask first.
- **No commits unless explicitly instructed.**
- **All scripts must be idempotent.** Guard with `Test-Path`, `Test-CommandExists`, registry checks, or winget `--exact` presence checks. Re-running `init.ps1` must be a no-op when nothing has changed.
- **`init.ps1` stays bootstrappable via `iwr | iex`.** Don't add dependencies on repo-local helpers before the clone step.
- **`inst-*.ps1` must be standalone and re-runnable.** Check for the binary/package before installing. Reinstall only when an explicit `-Force` switch is passed.
- **winget-first for software.** Chocolatey and Scoop are secondary. Never invoke `msiexec`/raw installers if a winget package exists.
- **Symlink configs, don't copy.** Use `CreateSymLink` from `functions.ps1`. If a real file/dir exists at the link target, investigate before overwriting — it may be the user's in-progress work.
- **Never commit secrets.** Keep tokens, SSH keys, and `.claude/settings.local.json`-style files out of git.
- **Don't reformat config files.** JSON, TOML, Lua, AHK — match the file's existing convention. No editor reflow.
- **Non-elevated when possible.** Use `RunAsUser` in AHK; elevate only when the operation truly needs it.
- **Pre-handoff checklist:** `make test` (Pester). After adding/removing exported functions, update the matching `.psd1` `FunctionsToExport`. Note any sudo/registry/system-state changes in the handoff.

## Stack

PowerShell 7 (primary), Windows PowerShell 5.1 (bootstrap fallback), AutoHotkey v2, Lua (configs), Pester (tests), winget + Scoop + Chocolatey (install), Windows Terminal, Starship. AI tooling synced via `scripts/sync-ai.ps1`.

## Commands

| Task | Command |
|---|---|
| Full bootstrap (admin) | `.\init.ps1` |
| Bootstrap + extended software | `.\init.ps1 -Software` |
| Remote bootstrap | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 \| iex` |
| Run test suite | `make test` (or `pwsh -NoProfile -c "Invoke-Pester -Path ./tests -Output Detailed"`) |
| Filter tests | `Invoke-Pester -Path ./tests -FullNameFilter "*pattern*"` |
| Single installer | `& .\scripts\inst-ssh.ps1` · `inst-pwsh.ps1` · `inst-terminal.ps1` |
| Load shared helpers in session | `. .\functions.ps1` |
| Reload a module | `Import-Module .\powershell\modules\helpers -Force` |
| Refresh module manifest | `UpdateModuleManifest -moduleManifestPath .\powershell\modules\helpers\helpers.psd1` |
| Sync AI tooling | `.\scripts\sync-ai.ps1` |
| Reload AHK | Edit + save (`~^s` auto-reload), or run `init-autohotkey.ahk` |

No linter/formatter is configured (no PSScriptAnalyzer, no `.editorconfig`). Don't add one without asking.

## Layout

```
init.ps1                Bootstrap entry (remote-curl-installable)
init-software.ps1       Extended software install (-Software flag)
init-autohotkey.ahk     AHK v2 entry, includes all AHK modules
functions.ps1           Shared PS utilities (symlinks, permissions, module manifest)
Makefile                Test orchestration

autohotkey/             AHK v2 modules (hotkeys, window mgmt, terminal toggle)
powershell/             PS profile, completions, configs
powershell/modules/
    aliases/            Global aliases (git, docker, …)
    helpers/            Exported utility functions (sync with .psd1)
scripts/                inst-*, wsl-*, sync-ai, cleanup, etc.
configs/                Registry (.reg) files
terminal/               Windows Terminal profiles.json
bin/                    User binaries (on PATH)
tests/                  Pester *.Tests.ps1 suites
tmp/                    Scratch (gitignored — never commit)
```

### Script naming

`scripts/{category}-{name}.ps1`:

| Prefix | Use |
|---|---|
| `inst-` | Installers for a single tool/package (idempotent) |
| `wsl-` | WSL-specific (requires WSL interop) |
| `sync-` | Sync/mirror operations (AI tooling, configs) |
| Uncategorised | One-offs: `cleanup.ps1`, `auth.ps1`, `compact-wsl.ps1`, `ipv6.ps1`, `fix-*` |

## Conventions

### PowerShell

- **Exported functions:** `Verb-Noun` PascalCase (`Test-CommandExists`, `Add-DefenderExclusion`).
- **Short aliases:** lowercase abbreviated (`gs`, `gc`, `gp`, `gk`).
- **Internal helpers:** PascalCase without dash (`SetPermissions`, `CreateSymLink`) or camelCase (`buildWebConfig`).
- **Variables:** `camelCase`. **Constants/exports:** `UPPER_SNAKE` (`$DOTFILES`, `$SCRIPTS_DIR`).
- `param()` at function top; mark required with `[Parameter(Mandatory)]`; type-annotate (`[string]`, `[switch]`, `[string[]]`); validate with `[ValidateSet()]`.
- Error handling: `try/catch` with `Write-Error`/`Write-Warning`; `$ErrorActionPreference = "Stop"` in critical scripts; check `$LASTEXITCODE` after native commands (git/wsl/winget).
- Guard every file op with `Test-Path`. Build paths with `Join-Path`. Canonical root is `$env:USERPROFILE\winconf`.
- Console output: `Write-Host -ForegroundColor` — Cyan info, Green ok, Yellow warn, Red err, DarkGray detail. Prefer the `Write-Step`/`Write-OK`/`Write-Skip`/`Write-Fail` helpers when already defined in the script.
- Module system: dot-source with `. $PSScriptRoot\file.ps1`. After adding/removing a function, update `FunctionsToExport` in the `.psd1`. Remove built-in alias conflicts with `Remove-Item -Force Alias:$alias`.
- Use splatting (`@params`) for long cmdlet calls.

### AutoHotkey v2

- Every `.ahk` starts with `#Requires AutoHotkey v2.0`.
- Functions PascalCase (`ToggleTerminal`, `RunOrActivate`), variables camelCase, globals declared with `global`.
- Modifiers: `#` Win, `!` Alt, `+` Shift, `^` Ctrl.
- Wrap window ops in `try/catch` — windows can vanish mid-operation. Always `WinExist()` before `WinActivate()`. Use `WinWaitActive` with a timeout after launching processes.
- Identify windows via `ahk_exe` / `ahk_class` / `ahk_id`. Track handles in `Map()` globals.
- `#Include` paths use quotes. DLL interop via `DllCall` (virtual desktop accessor).

### PowerShell version detection

```powershell
if ($PSVersionTable.PSVersion.Major -ge 7) { ... }
if ([Environment]::Is64BitOperatingSystem) { ... }
if (Get-Command winget -ErrorAction SilentlyContinue) { ... }
```

## Deep Dives

Read the relevant doc before touching the area it covers:

- [docs/bootstrap.md](docs/bootstrap.md) — `init.ps1` flow, fresh-vs-update modes, `$SOURCE_FILES` order, idempotency rules for `inst-*.ps1`.
- [docs/testing.md](docs/testing.md) — Pester suites, filters, what the layer deliberately does not cover.
- [docs/shell-env.md](docs/shell-env.md) — profile load order, `functions.ps1` helpers, `helpers` / `aliases` module layout, manifest discipline.
- [docs/ai-sync.md](docs/ai-sync.md) — `sync-ai.ps1` sequence, skill/MCP layout, Windows vs WSL paths.
- [docs/help.md](docs/help.md) — keyboard shortcuts (AHK hotkeys, git aliases, bootstrap commands).

## Git & PR

- Commit subjects: short, lowercase, imperative (`add winscp to essential software`, `fix pwsh profile loading`, `update readme`).
- Verbs: `add`, `fix`, `update`, `remove`, `save`. No conventional-commit prefixes.
- Direct commits to `main` — no PR workflow.

## Notes for agents

- `tmp/` is gitignored scratch — don't commit files there.
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` — this file is the source of truth.
- PowerShell modules load from `$env:USERPROFILE\winconf\powershell\modules`.
- AHK auto-reloads on save when the editor's `~^s` hook is installed.
- Pester tests may touch real registry / filesystem — read the test before running if unsure.
