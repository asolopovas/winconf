# Testing

Pester tests run locally against the live Windows environment. Some touch registry, filesystem, symlinks, package managers, or apps.

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
| `scripts.Tests.ps1` | script syntax and smoke behavior |
| `sync-ai.Tests.ps1` | AI sync logic |
| `aimp.Tests.ps1` | AIMP helper/hotkey glue |
| `just-completion.Tests.ps1` | just completions |
| `paths-doctor.Tests.ps1` | PATH diagnostics |

## Rules

- Pattern: `tests/<target>.Tests.ps1`.
- Use `BeforeAll`/`AfterAll` for state.
- Use `It -Skip` when dependencies are missing.
- Keep `make test` under one warm-machine minute.
- Prefer integration checks; mock only for isolated pure functions.
- Mention real system mutations in the handoff.

## Missing by design

No CI, PSScriptAnalyzer, `.editorconfig`, Docker harness, or clean-image bootstrap harness. Do not add them without approval.

## Handoff checks

| Changed area | Check |
|---|---|
| Any code | `make test` |
| `init.ps1` or `scripts/inst-*.ps1` | clean-VM/fresh-run coverage or skipped note |
| AHK | reload `init-autohotkey.ahk`; verify affected hotkey when practical |
| `powershell/modules/**` | `Import-Module -Force`; confirm `.psd1` exports |
| Registry/system scripts | mention system-state changes |
