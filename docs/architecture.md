# Architecture

`winconf` provisions one Windows user profile. Scripts own machine state; docs define contracts; tests verify idempotency.

## Layers

| Layer | Paths | Owns |
|---|---|---|
| Bootstrap | `init.ps1`, `init-software.ps1` | admin entry, clone/update mode, essential packages, setup order |
| Installers | `scripts/inst-*.ps1` | one idempotent tool/setup unit per file |
| System scripts | other `scripts/*.ps1` | cleanup, WSL, auth, diagnostics, repairs |
| Root helpers | `functions.ps1` | setup-safe shared helpers |
| PowerShell | `powershell/` | profiles, completions, modules, configs |
| AutoHotkey | `init-autohotkey.ahk`, `autohotkey/` | hotkeys, windows, terminal, app launchers |
| Configs | `configs/`, `terminal/` | registry and Windows Terminal state |
| Tests | `tests/`, `Makefile` | Pester validation |
| Docs | `README.md`, `AGENTS.md`, `docs/` | operating contracts |

## Dependency direction

- `init.ps1` may define local helpers because the repo may not exist yet.
- `scripts/inst-*.ps1` may dot-source `functions.ps1` after clone but must run directly.
- Modules must load without the interactive profile.
- Tests may touch live Windows state; make side effects explicit.
- AHK automation must target HWNDs and close only windows it created.

## Script naming

| Pattern | Use |
|---|---|
| `inst-<name>.ps1` | installer/setup unit |
| `wsl-<name>.ps1` | WSL work |
| `sync-<name>.ps1` | sync/mirror workflow |
| `fix-<name>.ps1` | repair workflow |

## Change rules

- Put details in the narrowest doc; keep `AGENTS.md` as the map.
- Promote repeated review feedback into tests, guards, or docs.
- Prefer shared helpers over repeated probes when the invariant matters.
- Keep bootstrap readable; failures should include command, package/path, and next action.
