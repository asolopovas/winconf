# Shell environment

PowerShell state lives in profile startup, root helpers, and importable modules.

## Load order

PowerShell 7:

1. `powershell/Microsoft.Powershell_profile.ps1`
2. `powershell/Profile.ps1`
3. repo modules in `PSModulePath`
4. `helpers`
5. `aliases`
6. completions
7. Starship

Keep Windows PowerShell 5.1 shims out of the 7 path.

## Root helpers

`functions.ps1` stays setup-safe because installers dot-source it. Load with `. .\functions.ps1`.

| Helper | Purpose |
|---|---|
| `Test-CommandExists` | command check |
| `SetPermissions` | grant current user full control |
| `CreateSymLink` | replace source path with symlink |
| `Select-FromMenu` | interactive picker |
| `Mount-Btrfs` / `Dismount-Btrfs` | elevated WSL disk mounts |

## Modules

| Module | Path | Owns |
|---|---|---|
| `helpers` | `powershell/modules/helpers/` | exported utilities by topic |
| `aliases` | `powershell/modules/aliases/` | git/package aliases and conflict removal |

Each module has a `.psm1` loader and `.psd1` manifest; keep exports synced.

## Placement

| Need | File |
|---|---|
| Files/paths | `helpers/files.ps1` |
| Docker Compose | `helpers/docker-compose.ps1` |
| Hosts/firewall/security/WSL | matching helper file |
| Git aliases | `aliases/git-aliases.ps1` |
| Package aliases | `aliases/package-managers.ps1` |
| Alias conflicts | `aliases/remove-aliases.ps1` |

Do not use `tools.ps1` when a topical file exists.

## Rules

- Exported functions use `Verb-Noun`; internal helpers use PascalCase or camelCase.
- Variables use camelCase; constants use `UPPER_SNAKE`.
- Put `param()` first; type parameters; mark mandatory parameters.
- Build paths with `Join-Path`; repo root is `$env:USERPROFILE\winconf`.
- Use `Test-Path`, strict mode, stop-on-error, `try`/`catch`, and `$LASTEXITCODE` checks around external state.
- Use existing `Write-Step`/`Write-OK`/`Write-Skip`/`Write-Fail` for setup output.
- Keep repo constants in `init.ps1`.

## Refresh

```powershell
UpdateModuleManifest -moduleManifestPath .\powershell\modules\helpers\helpers.psd1
Import-Module .\powershell\modules\helpers -Force
```
