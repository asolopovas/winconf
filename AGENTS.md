---
name: winconf
description: Agent map for the Windows dotfiles and provisioning repo
---

# AGENTS

Repo is source of truth. Keep details in docs, scripts, tests, or checked plans.

## Contract

- Personal Windows dotfiles at `$env:USERPROFILE\winconf`.
- Stack: PowerShell, AutoHotkey v2, Lua, Pester, winget/Scoop/Chocolatey.
- Idempotent unless `-Force`; prefer winget over raw installers.
- `init.ps1` works locally and through remote `iwr | iex` before clone.
- `scripts/inst-*.ps1` work standalone after clone.
- Symlink repo configs with `CreateSymLink`; inspect targets first.
- No comments except shebangs, `#Requires`, and interpreter pragmas.
- Do not reformat configs or add linters/CI without approval.
- Never commit secrets, local AI settings, or unrequested commits.
- Avoid elevation unless required.

## Commands

Bootstrap `.\init.ps1`; apps `.\init.ps1 -Software`; remote `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex`; test `make test`; sync AI `.\scripts\sync-ai.ps1`; helpers `. .\functions.ps1`.

## Docs

- `docs/architecture.md`: layers, rules, plans.
- `docs/bootstrap.md`: bootstrap and installers.
- `docs/shell-env.md`: PowerShell and modules.
- `docs/testing.md`: tests and handoff.
- `docs/ai-sync.md`: AI tool sync.
- `docs/help.md`: hotkeys and aliases.

## Loop

Inspect -> plan -> change -> check -> review diff -> update docs/tests -> hand off validation and skipped checks.
