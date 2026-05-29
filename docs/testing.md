# Testing

Tests are local Pester suites run by `make test`. They validate the live Windows environment; some touch registry, filesystem, symlinks, package managers, or running apps.

## Run

| Scope | Command |
|---|---|
| All tests | `make test` |
| All tests direct | `pwsh -NoProfile -Command "Invoke-Pester -Path './tests' -Output Detailed"` |
| Filter by name | `Invoke-Pester -Path ./tests -FullNameFilter "*CreateSymLink*"` |
| One file | `Invoke-Pester -Path ./tests/functions.Tests.ps1 -Output Detailed` |

## Suites

| Suite | Scope |
|---|---|
| `functions.Tests.ps1` | root helper behavior |
| `helpers.Tests.ps1` | exported helpers module functions |
| `scripts.Tests.ps1` | script syntax and smoke behavior |
| `sync-ai.Tests.ps1` | AI credential, MCP, and skill sync logic |
| `aimp.Tests.ps1` | AIMP helper and hotkey glue |
| `just-completion.Tests.ps1` | completion generation behavior |
| `paths-doctor.Tests.ps1` | PATH diagnostics |

## Rules

- Test file pattern: `tests/<target>.Tests.ps1`.
- Use `BeforeAll` and `AfterAll` for state setup/cleanup.
- Use `It -Skip` when a local dependency is missing.
- Keep `make test` under one minute on a warm machine.
- Prefer integration checks for installers and helpers.
- Mock only when isolating a pure function is clearer than touching system state.
- Note any real system mutation in the handoff.

## Not present

- No CI.
- No PSScriptAnalyzer.
- No `.editorconfig`.
- No Docker or clean-image bootstrap harness.

Do not add these without approval.

## Pre-handoff validation

| Changed area | Validate |
|---|---|
| Any code | `make test` |
| `init.ps1` or `scripts/inst-*.ps1` | State clean-VM/fresh-run coverage or that it was skipped |
| AHK modules | Reload `init-autohotkey.ahk`; verify affected hotkey when practical |
| `powershell/modules/**` | `Import-Module -Force`; confirm `.psd1` exports |
| Registry/system scripts | Mention system-state changes |
