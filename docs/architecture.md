# Architecture

`winconf` provisions one Windows user profile. Repo files are the only agent-visible truth; encode decisions as docs, scripts, tests, schemas, or checked plans.

## Layers

| Layer | Paths | Owns |
|---|---|---|
| Bootstrap | `init.ps1`, `init-software.ps1` | entry, clone/update, essentials, order |
| Installers | `scripts/inst-*.ps1` | idempotent setup units |
| System scripts | other `scripts/*.ps1` | cleanup, WSL, auth, diagnostics, repair |
| Helpers | `functions.ps1` | setup-safe shared functions |
| Shell | `powershell/` | profiles, modules, completions, configs |
| AutoHotkey | `init-autohotkey.ahk`, `autohotkey/` | hotkeys, windows, app launchers |
| Configs | `configs/`, `terminal/` | registry and Terminal state |
| Tests | `tests/`, `Makefile` | Pester checks |
| Docs | `README.md`, `AGENTS.md`, `docs/` | contracts and handoff guidance |

## Rules

- `AGENTS.md` is a map, not a manual.
- `init.ps1` carries pre-clone helpers; later scripts may dot-source `functions.ps1`.
- Installers run directly, repeatedly, and without profile state.
- Modules load without profiles; manifests match exports.
- Tests may touch live Windows state; state side effects in handoff.
- AHK files start with `#Requires AutoHotkey v2.0`; functions use PascalCase; globals are explicit.
- AHK targets windows by `ahk_exe`, `ahk_class`, or `ahk_id`, checks `WinExist()`, and closes only windows it creates.
- From Git Bash/MSYS, set `MSYS2_ARG_CONV_EXCL='*'` before slash-prefixed AHK switches.

## Names

| Pattern | Use |
|---|---|
| `inst-<name>.ps1` | installer/setup unit |
| `wsl-<name>.ps1` | WSL workflow |
| `sync-<name>.ps1` | sync/mirror workflow |
| `fix-<name>.ps1` | repair workflow |

## Plans and isolation

- Small change: inline plan.
- Complex change: checked plan in `docs/exec-plans/active/` with goal, scope, acceptance criteria, progress, decisions, validation, and follow-up debt; move to `completed/` when done.
- Concurrent or risky change: isolated git worktree.

## Enforcement

- Prefer mechanical checks: Pester, manifests, smoke checks, explicit failures.
- Failure messages include command, package/path, and next action.
- Promote repeated review feedback into tests, guards, or docs.
- Track harness gaps in `docs/exec-plans/tech-debt-tracker.md`.
- No CI, lint, Docker, browser-control app harness, or local observability stack exists; add only with approval.

## Agent loop

Inspect -> plan -> change -> run checks -> review diff -> update docs/tests -> hand off validation, skipped checks, and state changes.
