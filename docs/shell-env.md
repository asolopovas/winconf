# Shell environment

PowerShell state is split between the profile, root bootstrap helpers, and importable modules.

## Load order

PowerShell 7 loads:

1. `$PROFILE` at `powershell/Microsoft.Powershell_profile.ps1`
2. `powershell/Profile.ps1`
3. repo module path appended to `PSModulePath`
4. `helpers` module
5. `aliases` module
6. completions
7. Starship

Windows PowerShell 5.1 has a separate profile. Keep 5.1-only compatibility out of the PowerShell 7 path.

## Root helpers

`functions.ps1` is intentionally small because setup scripts dot-source it.

| Helper | Purpose |
|---|---|
| `Test-CommandExists <cmd>` | Boolean `Get-Command` check |
| `SetPermissions <dir>` | Grant current user full control |
| `CreateSymLink <src> <target>` | Replace source path with a symlink |
| `Select-FromMenu` | Interactive list picker |
| `Mount-Btrfs` / `Dismount-Btrfs` | Elevated WSL disk mount helpers |

Load manually with `. .\functions.ps1`.

## Modules

| Module | Path | Contract |
|---|---|---|
| `helpers` | `powershell/modules/helpers/` | Exported utility functions split by topic |
| `aliases` | `powershell/modules/aliases/` | Git, package-manager, and conflict-removal aliases |

Each module has:

- `.psm1` loader that dot-sources local `.ps1` files.
- `.psd1` manifest that controls exported functions or aliases.

After adding/removing an exported function or alias, update the manifest.

## Helper placement

| Need | Put it in |
|---|---|
| File/path utilities | `helpers/files.ps1` |
| Docker Compose wrappers | `helpers/docker-compose.ps1` |
| Hosts/firewall/security | matching helper file |
| WSL helpers | `helpers/wsl.ps1` |
| Git alias | `aliases/git-aliases.ps1` |
| Package-manager alias | `aliases/package-managers.ps1` |
| Built-in alias conflict | `aliases/remove-aliases.ps1` |

Do not use `tools.ps1` as a dumping ground when a topical file exists.

## Rules

- Build paths with `Join-Path`.
- Root is `$env:USERPROFILE\winconf`.
- Keep repo constants in `init.ps1`, not duplicated across installers.
- Use `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` for scripts that touch external systems.
- Check `$LASTEXITCODE` after native tools.
- Prefer topic-specific helpers over repeated one-off code when behavior is reused.

## Refresh

```powershell
UpdateModuleManifest -moduleManifestPath .\powershell\modules\helpers\helpers.psd1
Import-Module .\powershell\modules\helpers -Force
```
