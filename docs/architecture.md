# Architecture

`winconf` provisions one Windows user profile. Repo files are the only agent-visible truth; encode decisions as docs, scripts, tests, schemas, or checked plans.

## Layers

| Layer | Paths | Owns |
|---|---|---|
| Bootstrap | `init.ps1`, `init-software.ps1` | entry, clone/update, essentials, order |
| Installers | `scripts/inst-*.ps1` | one idempotent setup unit |
| System scripts | other `scripts/*.ps1` | cleanup, WSL, auth, diagnostics, repair |
| Helpers | `functions.ps1` | setup-safe shared functions |
| Shell | `powershell/` | profiles, modules, completions, configs |
| AutoHotkey | `init-autohotkey.ahk`, `autohotkey/` | hotkeys, windows, app launchers |
| Configs | `configs/`, `terminal/` | registry and Windows Terminal state |
| Tests | `tests/`, `Makefile` | Pester checks |
| Docs | `README.md`, `AGENTS.md`, `docs/` | contracts and handoff guidance |

## Boundaries

- `AGENTS.md` is a map, not a manual.
- `init.ps1` carries pre-clone helpers; later scripts may dot-source `functions.ps1`.
- Installers run directly, repeatedly, and without interactive profiles.
- Modules load without profiles; manifests match exports.
- Tests may touch live Windows state; state side effects explicitly.
- AHK files start with `#Requires AutoHotkey v2.0`; functions use PascalCase; globals are explicit.
- AHK targets windows by `ahk_exe`, `ahk_class`, or `ahk_id`, checks `WinExist()` before activation, and closes only windows it creates.
- From Git Bash/MSYS, set `MSYS2_ARG_CONV_EXCL='*'` before slash-prefixed AHK switches.

## Naming

| Pattern | Use |
|---|---|
| `inst-<name>.ps1` | installer/setup unit |
| `wsl-<name>.ps1` | WSL workflow |
| `sync-<name>.ps1` | sync/mirror workflow |
| `fix-<name>.ps1` | repair workflow |

## Planning and isolation

- Use a short inline plan for small work.
- For complex work, check an execution plan into `docs/exec-plans/active/` with goal, scope, acceptance criteria, progress, decisions, validation, and follow-up debt; move it to `completed/` when done.
- Use isolated git worktrees for concurrent or risky tasks.

## Enforcement

- Encode repeated review feedback as tests, guards, or docs.
- Keep invariants mechanical when practical: Pester, manifests, smoke checks, and explicit failures.
- Failure messages include command, package/path, and next action.
- No CI, lint, Docker, browser, app runtime, or observability harness exists yet; do not add without approval.

## Agent loop

Inspect repo -> plan -> change -> run checks -> review diff -> update docs/tests -> hand off with validation, skipped checks, and state changes.
