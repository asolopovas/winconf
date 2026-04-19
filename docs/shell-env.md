## Shell Environment

### Load order (PowerShell 7)

`$PROFILE` (`Microsoft.PowerShell_profile.ps1`) → `powershell/Profile.ps1` → `PSModulePath` augmented with `$env:USERPROFILE\winconf\powershell\modules` → `helpers` module → `aliases` module (which dot-sources `git-aliases.ps1`, `package-managers.ps1`, `remove-aliases.ps1`) → completions → Starship init.

Windows PowerShell 5.1 uses its own profile path — keep 5.1-only shims out of the 7 profile.

### functions.ps1 (repo root) cheat sheet

| Helper | Purpose |
|---|---|
| `Test-CommandExists <cmd>` | `Get-Command` wrapper returning `[bool]` |
| `SetPermissions <dir>` | Grants `$env:UserName` FullControl on `$dir` |
| `CreateSymLink <src> <target>` | Deletes `$src`, creates symlink to `$target` |

Load in a session via `. .\functions.ps1`. These are intentionally tiny — heavier utilities live in the `helpers` module.

### Modules

| Module | Path | Contents |
|---|---|---|
| `helpers` | `powershell/modules/helpers/` | Split by topic: `conversions.ps1`, `docker-compose.ps1`, `edit-hosts.ps1`, `files.ps1`, `firewall-blocker.ps1`, `rm-pattern.ps1`, `security.ps1`, `shortcuts.ps1`, `system.ps1`, `tools.ps1`, `wsl.ps1` |
| `aliases` | `powershell/modules/aliases/` | `git-aliases.ps1`, `package-managers.ps1`, `remove-aliases.ps1` |

Both use a `.psm1` loader that dot-sources the `.ps1` files and a `.psd1` manifest that declares `FunctionsToExport` / `AliasesToExport`. **After adding or removing a function, update the matching manifest** — otherwise it won't be visible to the importer.

Refresh a manifest programmatically:

```powershell
UpdateModuleManifest -moduleManifestPath .\powershell\modules\helpers\helpers.psd1
```

### Conventions

- New shared utility → pick a file in `helpers/` by topic; don't dump everything into `tools.ps1`.
- New alias → `powershell/modules/aliases/` (git-shaped → `git-aliases.ps1`; package managers → `package-managers.ps1`).
- Built-in alias conflicts (e.g. `gc`, `gp`) are removed up-front via `Remove-Item -Force Alias:$name` in `remove-aliases.ps1`. Add to that list when a new clash appears.
- Constants go in `init.ps1` (`$DOTFILES`, `$ESSENTIAL_SOFTWARE`) — don't redefine them in individual `inst-*.ps1` scripts.
- Path construction: `Join-Path` always. Root: `$env:USERPROFILE\winconf`.
- Coloured output: `Write-Host -ForegroundColor Cyan|Green|Yellow|Red|DarkGray`. Scripts that define `Write-Step`/`Write-OK`/`Write-Skip`/`Write-Fail` helpers should use those instead for consistency.
- `Set-StrictMode -Version Latest` + `$ErrorActionPreference = 'Stop'` in scripts that touch external systems (winget, git, registry, network).
