---
name: winconf
description: Agent guide for the Windows dotfiles and provisioning repo
---

# AGENTS

Use this file as the map. The source of truth lives in `docs/` and the scripts themselves.

## Repository contract

- Personal Windows dotfiles and dev bootstrap.
- Canonical path: `$env:USERPROFILE\winconf`.
- Primary stack: PowerShell 7, Windows PowerShell 5.1 bootstrap fallback, AutoHotkey v2, Lua configs, Pester tests, winget/Scoop/Chocolatey.
- Entry point: `init.ps1`, including remote `iwr | iex` bootstrap.

## Non-negotiables

- No comments in files. Allowed only: shebangs, `#Requires`, and interpreter pragmas.
- No commits unless explicitly requested.
- Scripts must be idempotent and safe to re-run.
- `init.ps1` must work before repo-local helpers exist.
- `scripts/inst-*.ps1` must be standalone, re-runnable, and reinstall only with explicit `-Force`.
- Prefer winget. Use Chocolatey/Scoop only when winget is unsuitable. Do not use raw installers when winget has a package.
- Symlink configs with `CreateSymLink`; investigate real files before replacing them.
- Never commit secrets or local AI settings.
- Do not reformat config files or introduce linters without approval.
- Avoid elevation unless the operation requires it.

## Commands

| Task | Command |
|---|---|
| Bootstrap | `.\init.ps1` |
| Bootstrap with extended software | `.\init.ps1 -Software` |
| Remote bootstrap | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Test | `make test` |
| Filter tests | `Invoke-Pester -Path ./tests -FullNameFilter "*pattern*"` |
| Load root helpers | `. .\functions.ps1` |
| Reload helpers module | `Import-Module .\powershell\modules\helpers -Force` |
| Sync AI tools | `.\scripts\sync-ai.ps1` |
| Reload AHK | run `init-autohotkey.ahk` or save an AHK file in the configured editor |

## Knowledge map

| Need | Read |
|---|---|
| Repo layout and layer boundaries | `docs/architecture.md` |
| Bootstrap flow, installer contract, source order | `docs/bootstrap.md` |
| PowerShell profile, modules, aliases, manifests | `docs/shell-env.md` |
| Tests and validation expectations | `docs/testing.md` |
| AI credential/MCP/skill sync | `docs/ai-sync.md` |
| Hotkeys and daily commands | `docs/help.md` |
| User-facing setup overview | `README.md` |

## Implementation rules

### PowerShell

- Exported functions: `Verb-Noun` PascalCase.
- Internal helpers: PascalCase without dash or camelCase.
- Variables: camelCase. Repo constants: `UPPER_SNAKE`.
- Put `param()` at the top; type parameters; use `[Parameter(Mandatory)]` where required.
- Guard file operations with `Test-Path`; build paths with `Join-Path`.
- Check `$LASTEXITCODE` after native tools.
- Use `try`/`catch` for registry, network, winget, git, WSL, and filesystem operations.
- After adding/removing exported functions, update the matching `.psd1` `FunctionsToExport`.
- Prefer `Write-Step`, `Write-OK`, `Write-Skip`, `Write-Fail` when already present; otherwise use `Write-Host -ForegroundColor` consistently.

### AutoHotkey v2

- Every `.ahk` starts with `#Requires AutoHotkey v2.0`.
- Functions use PascalCase; variables use camelCase; globals are explicit.
- Use `ahk_exe`, `ahk_class`, or `ahk_id` selectors.
- Check `WinExist()` before `WinActivate()`; window operations need `try`/`catch`.
- Do not kill arbitrary `WindowsTerminal`, `wt`, or `AutoHotkey` processes in tests.
- When launching AHK from Git Bash/MSYS, set `MSYS2_ARG_CONV_EXCL='*'` before slash-prefixed switches.

## Handoff checklist

- Run `make test` unless impossible.
- For bootstrap or installer changes, state whether a clean-VM run was performed.
- For AHK changes, reload `init-autohotkey.ahk` and verify the affected hotkey when practical.
- For PowerShell module exports, confirm the `.psd1` manifest is synced.
- Mention skipped validation and any registry, sudo, package-manager, or system-state changes.
