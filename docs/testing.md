## Testing

Single Pester layer, run from `make`. No Docker, no integration harness — tests execute against the live machine, so some of them touch real state.

### Run everything — `make test`

```
pwsh -NoProfile -Command "Invoke-Pester -Path './tests' -Output Detailed"
```

Current suites under `tests/`:

| Suite | Scope |
|---|---|
| `functions.Tests.ps1` | `functions.ps1` helpers (`Test-CommandExists`, `SetPermissions`, `CreateSymLink`) |
| `helpers.Tests.ps1` | `powershell/modules/helpers` — exported utility functions |
| `scripts.Tests.ps1` | `scripts/*.ps1` — syntax + behavioural smoke checks |
| `sync-ai.Tests.ps1` | `scripts/sync-ai.ps1` — credential/MCP/skill sync |
| `aimp.Tests.ps1` | AIMP-related helpers / hotkey glue |

### Filter

```powershell
Invoke-Pester -Path ./tests -FullNameFilter "*CreateSymLink*"
Invoke-Pester -Path ./tests/functions.Tests.ps1 -Output Detailed
```

### Conventions

- File pattern: `tests/<target>.Tests.ps1`.
- Use `BeforeAll` / `AfterAll` for state. Use `It -Skip` when a dependency is missing (winget, WSL, specific app).
- Tests that mutate real system state (registry, symlinks in `$env:USERPROFILE`, winget installs) **must** be noted in the PR/handoff.
- Don't mock winget/git by default — the suite is integration-first, matching the idempotent-install philosophy. If you need pure-unit coverage, isolate the function and mock at the Pester level.
- Keep suites fast: the default `make test` target must finish in under a minute on a warm machine.

### What's deliberately missing

- No PSScriptAnalyzer, no `.editorconfig`, no style linter. Don't add one without the user's say-so.
- No CI — tests run locally only.
- No Docker equivalent of the bash-side `make test-init`. The Windows bootstrap is validated by running it on a clean VM; there's no automated bootstrapped-image harness.

### Pre-handoff checklist

`make test`. For changes that touch:

- `init.ps1` / `inst-*.ps1` → also describe what you ran on a clean VM (or state that you didn't).
- AHK modules → reload `init-autohotkey.ahk`, confirm the affected hotkey works.
- `powershell/modules/**` → reload the module (`Import-Module -Force`) and confirm `FunctionsToExport` is in sync with the `.psd1`.

Note any skipped layer in the handoff.
