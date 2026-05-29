# Architecture

`winconf` provisions one Windows user profile. Keep behavior legible from the repo: scripts own machine state, docs explain contracts, tests validate idempotency.

## Layers

| Layer | Paths | Owns |
|---|---|---|
| Bootstrap | `init.ps1`, `init-software.ps1` | Admin entry, clone/update mode, essential packages, ordered setup scripts |
| Installers | `scripts/inst-*.ps1` | One tool or capability per file, idempotent install/update behavior |
| System scripts | `scripts/*.ps1` except installers | Cleanup, WSL, auth, diagnostics, one-off maintenance |
| Root helpers | `functions.ps1` | Minimal helpers needed by setup scripts |
| PowerShell profile | `powershell/` | Profile load order, completions, Starship, module path |
| PowerShell modules | `powershell/modules/helpers`, `powershell/modules/aliases` | Exported functions and global aliases |
| AutoHotkey | `init-autohotkey.ahk`, `autohotkey/` | Hotkeys, window management, terminal toggle, app launchers |
| Configs | `configs/`, `terminal/`, `powershell/configs/` | Registry, Windows Terminal, PowerShell, Starship |
| Tests | `tests/`, `Makefile` | Pester validation for helpers, scripts, sync behavior, selected integrations |
| Docs | `README.md`, `AGENTS.md`, `docs/` | Human and agent operating contracts |

## Dependency direction

- `init.ps1` may define local bootstrap helpers because repo files may not exist yet.
- `scripts/inst-*.ps1` may dot-source `functions.ps1` after clone, but must also be safe as standalone scripts.
- Modules must not depend on the interactive profile to load.
- Tests may touch live Windows state; keep side effects explicit in test names and handoffs.
- AHK tests and scripts must target windows by HWND and close only windows they created.

## Script naming

| Pattern | Purpose |
|---|---|
| `scripts/inst-<name>.ps1` | Single-tool installer or setup unit |
| `scripts/wsl-<name>.ps1` | WSL-specific work |
| `scripts/sync-<name>.ps1` | Sync or mirror workflow |
| `scripts/fix-<name>.ps1` | Narrow repair workflow |
| Other `scripts/*.ps1` | Repo-local maintenance or diagnostics |

## Current top-level layout

| Path | Purpose |
|---|---|
| `init.ps1` | Main bootstrap/update entry |
| `init-software.ps1` | Remote wrapper for `init.ps1 -Software` |
| `init-autohotkey.ahk` | AHK entry point |
| `functions.ps1` | Root PowerShell helpers |
| `Makefile` | Test shortcut |
| `autohotkey/` | AHK modules and desktop switcher dependency |
| `bin/` | User binaries on PATH |
| `configs/` | Registry files |
| `powershell/` | Profiles, completions, modules, configs |
| `scripts/` | Installers and maintenance scripts |
| `terminal/` | Windows Terminal profile |
| `tests/` | Pester suites |
| `tmp/` | Gitignored scratch |

## Change rules

- Add source-of-truth details to the narrowest doc, then link from `AGENTS.md` only if agents must know where to look.
- Promote repeated review feedback into tests, script guards, or docs.
- Prefer small reusable helpers over repeated inline probes when the invariant matters.
- Keep bootstrap logic readable over clever; failures should tell the next agent what to do.
