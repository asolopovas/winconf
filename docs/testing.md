# Testing

Pester runs against the live Windows profile and may touch registry, filesystem, symlinks, package managers, or apps.

## Run

| Scope | Command |
|---|---|
| All | `make test` |
| Direct | `pwsh -NoProfile -Command "Invoke-Pester -Path './tests' -Output Detailed"` |
| Filter | `Invoke-Pester -Path ./tests -FullNameFilter "*CreateSymLink*"` |
| One file | `Invoke-Pester -Path ./tests/functions.Tests.ps1 -Output Detailed` |

## Suites

| Suite | Scope |
|---|---|
| `functions.Tests.ps1` | root helpers |
| `helpers.Tests.ps1` | helpers module exports |
| `scripts.Tests.ps1` | script syntax/smoke behavior |
| `sync-ai.Tests.ps1` | AI sync |
| `aimp.Tests.ps1` | AIMP helper/hotkey glue |
| `just-completion.Tests.ps1` | just completions |
| `paths-doctor.Tests.ps1` | PATH diagnostics |

## Rules

- Name tests `tests/<target>.Tests.ps1`.
- Use `BeforeAll`/`AfterAll` for state.
- Use `It -Skip` when dependencies are missing.
- Keep `make test` under one warm-machine minute.
- Prefer integration checks; mock only pure isolated functions.
- State real system mutations in handoff.

## Handoff checks

Handoff includes summary, acceptance covered, validation commands/results, state changes, skipped checks, and follow-ups.

| Changed area | Check |
|---|---|
| Any code | `make test` |
| `init.ps1` or `scripts/inst-*.ps1` | fresh-run/clean-VM coverage or skipped reason |
| AHK | reload `init-autohotkey.ahk`; verify affected hotkey when practical |
| `powershell/modules/**` | `Import-Module -Force`; confirm `.psd1` exports |
| Registry/system scripts | mention state changes |
| Docs only | review links and affected contracts |

## Missing

No CI, PSScriptAnalyzer, `.editorconfig`, Docker, clean-image bootstrap, browser-control, or observability harness. Add only with approval.
