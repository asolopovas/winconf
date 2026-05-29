# Shell environment

PowerShell state is split between profile startup, root helpers, and importable modules.

## PowerShell 7 load order

1. `$PROFILE` at `powershell/Microsoft.Powershell_profile.ps1`
2. `powershell/Profile.ps1`
3. repo modules added to `PSModulePath`
4. `helpers`
5. `aliases`
6. completions
7. Starship

Windows PowerShell 5.1 has a separate profile; keep 5.1 shims out of the 7 path.

## Root helpers

`functions.ps1` stays small because setup scripts dot-source it.

| Helper | Purpose |
|---|---|
| `Test-CommandExists <cmd>` | Boolean command check |
| `SetPermissions <dir>` | Grant current user full control |
| `CreateSymLink <src> <target>` | Replace source path with symlink |
| `Select-FromMenu` | Interactive picker |
| `Mount-Btrfs` / `Dismount-Btrfs` | Elevated WSL disk mounts |

Load with `. .\functions.ps1`.

## Modules

| Module | Path | Owns |
|---|---|---|
| `helpers` | `powershell/modules/helpers/` | exported utility functions by topic |
| `aliases` | `powershell/modules/aliases/` | git/package aliases and conflict removal |

Each module has a `.psm1` loader and `.psd1` manifest. Keep exports in the manifest synced.

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

- Build paths with `Join-Path`; root is `$env:USERPROFILE\winconf`.
- Keep repo constants in `init.ps1`.
- Use strict mode and stop-on-error for scripts touching external systems.
- Check `$LASTEXITCODE` after native tools.
- Prefer shared helpers when behavior repeats.

## Refresh

```powershell
UpdateModuleManifest -moduleManifestPath .\powershell\modules\helpers\helpers.psd1
Import-Module .\powershell\modules\helpers -Force
```
