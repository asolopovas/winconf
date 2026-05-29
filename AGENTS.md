---
name: winconf
description: Agent map for the Windows dotfiles and provisioning repo
---

# AGENTS

Use the repo as source of truth. Keep this file a map; put details in focused docs, scripts, tests, or checked plans.

## Contract

- Personal Windows dotfiles at `$env:USERPROFILE\winconf`.
- Stack: PowerShell, AutoHotkey v2, Lua, Pester, winget/Scoop/Chocolatey.
- Idempotent by default; reinstall only with explicit `-Force`.
- `init.ps1` must run locally and through remote `iwr | iex` before clone.
- `scripts/inst-*.ps1` must be standalone after clone.
- Prefer winget; avoid raw installers when winget exists.
- Symlink repo-owned configs with `CreateSymLink`; inspect real targets first.
- No comments except shebangs, `#Requires`, and interpreter pragmas.
- Do not reformat configs or add linters/CI without approval.
- Never commit secrets, local AI settings, or unrequested commits.
- Avoid elevation unless required.

## Commands

| Task | Command |
|---|---|
| Bootstrap | `.\init.ps1` |
| Extended bootstrap | `.\init.ps1 -Software` |
| Remote bootstrap | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Test | `make test` |
| Sync AI tools | `.\scripts\sync-ai.ps1` |
| Load helpers | `. .\functions.ps1` |

## Docs

| Need | Read |
|---|---|
| Layers, rules, task loop | `docs/architecture.md` |
| Bootstrap/installers | `docs/bootstrap.md` |
| PowerShell profile/modules | `docs/shell-env.md` |
| Tests and handoff | `docs/testing.md` |
| AI sync | `docs/ai-sync.md` |
| Hotkeys/aliases | `docs/help.md` |

## Loop

Inspect repo -> plan -> change -> run checks -> review diff -> update docs/tests -> hand off with validation and skipped checks.
