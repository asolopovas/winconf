---
name: winconf
description: Agent map for the Windows dotfiles and provisioning repo
---

# AGENTS

Map only. Source of truth lives in focused docs and scripts.

## Contract

- Personal Windows dotfiles at `$env:USERPROFILE\winconf`.
- Stack: PowerShell, AutoHotkey v2, Lua configs, Pester, winget/Scoop/Chocolatey.
- Bootstrap: `init.ps1`, including remote `iwr | iex`.
- No comments in files except shebangs, `#Requires`, and interpreter pragmas.
- No commits unless requested.
- Idempotent scripts only.
- `init.ps1` must not need repo-local helpers before clone.
- `scripts/inst-*.ps1` must be standalone and reinstall only with `-Force`.
- Prefer winget over Chocolatey/Scoop; avoid raw installers when winget exists.
- Symlink repo configs with `CreateSymLink`; inspect real targets before replacing.
- Never commit secrets or local AI settings.
- Do not reformat configs or add linters without approval.
- Avoid elevation unless required.

## Commands

| Task | Command |
|---|---|
| Bootstrap | `.\init.ps1` |
| Extended bootstrap | `.\init.ps1 -Software` |
| Remote bootstrap | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Test | `make test` |
| Sync AI tools | `.\scripts\sync-ai.ps1` |
| Load root helpers | `. .\functions.ps1` |

## Docs

| Need | Read |
|---|---|
| Repo layers | `docs/architecture.md` |
| Bootstrap/installers | `docs/bootstrap.md` |
| PowerShell profile/modules | `docs/shell-env.md` |
| Tests/handoff validation | `docs/testing.md` |
| AI sync | `docs/ai-sync.md` |
| Hotkeys/aliases | `docs/help.md` |

## PowerShell rules

- Exported functions: `Verb-Noun`; internal helpers: PascalCase or camelCase; variables: camelCase; constants: `UPPER_SNAKE`.
- Put `param()` first; type parameters; mark mandatory parameters.
- Use `Test-Path`, `Join-Path`, `try`/`catch`, and `$LASTEXITCODE` checks around external state.
- Keep module manifests in sync with exports.
- Use existing `Write-Step`/`Write-OK`/`Write-Skip`/`Write-Fail`; otherwise use consistent `Write-Host -ForegroundColor`.

## AutoHotkey rules

- Every `.ahk` starts with `#Requires AutoHotkey v2.0`.
- Functions: PascalCase; variables: camelCase; globals explicit.
- Select windows by `ahk_exe`, `ahk_class`, or `ahk_id`.
- Check `WinExist()` before `WinActivate()` and wrap fragile window ops.
- Tests must close only windows they create.
- From Git Bash/MSYS, set `MSYS2_ARG_CONV_EXCL='*'` before slash-prefixed AHK switches.

## Before handoff

Run `make test` unless impossible. Follow `docs/testing.md` for area-specific checks and note skipped validation or system-state changes.
