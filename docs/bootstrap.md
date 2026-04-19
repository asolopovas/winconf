## Bootstrap (init.ps1)

Single-file entry — safe to `iwr | iex` before the repo is cloned. Re-runs detect an existing install and switch to update mode. Every `inst-*.ps1` checks for prior install before doing work.

### Invocation

```powershell
.\init.ps1                                   # fresh install or update (prompted)
.\init.ps1 -Software                         # also run inst-software.ps1
iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex
```

Must run in an **elevated** PowerShell (admin). Transcript lands in `$env:TEMP\winconf.log`.

### Modes

| Mode | Trigger | Does |
|---|---|---|
| Fresh install | `$DOTFILES` missing | resets winget sources, installs `$ESSENTIAL_SOFTWARE` in parallel jobs, clones repo, fixes ACLs, runs `$SOURCE_FILES` |
| Update | `$DOTFILES` present | prompts, `git pull`, `winget upgrade` only for essential IDs that actually have updates, re-runs `$SOURCE_FILES` with `-Update` for `inst-modules` |

### Key variables (top of `init.ps1`)

| Var | Purpose |
|---|---|
| `$DOTFILES` | `$env:USERPROFILE\winconf` — canonical root |
| `$SCRIPTS_DIR` | `$DOTFILES\scripts` |
| `$REPO_URL` | GitHub remote |
| `$AUTOHOTKEYVERSION` | Pinned to `2` — passed to `inst-ahk.ps1` |
| `$ESSENTIAL_SOFTWARE` | winget IDs installed on fresh, upgraded in update mode |
| `$PINNED_SOFTWARE` | winget IDs pinned (held back from upgrades) |
| `$SOURCE_FILES` | Ordered list of scripts run after bootstrap |

Add a new installer by appending its name (without `.ps1`) to `$SOURCE_FILES` in the right spot. Order matters: paths → fonts → pwsh → terminal → ahk → wsl → modules → scoop.

### Idempotency rules for `inst-*.ps1`

- Guard with `Test-CommandExists`, `Test-Path`, or a winget `--exact` presence check before installing.
- Reinstall only when an explicit `-Force` switch is passed in.
- Don't assume PATH is set — recheck with `Get-Command` after any installer that modifies it.
- Prefer `winget install --id <id> -h --accept-source-agreements --accept-package-agreements` with `2>$null` for noise suppression.
- When symlinking, use `CreateSymLink` from `functions.ps1` (it removes the target first).
- Log every step with colour: Cyan info / Green ok / Yellow warn / Red fail / DarkGray detail.

### Software install contract

Fresh runs install Git first (needed to clone), then fan out the remaining essentials as background jobs (`Start-Job`) and `Wait-Job`. Update runs only upgrade IDs that appear in `winget upgrade` output — no blanket reinstall.

Winget pins are applied at the end (`winget pin add`) for every ID in `$PINNED_SOFTWARE` that isn't already pinned.

### Test it

`make test` runs the Pester suite, which includes `scripts.Tests.ps1` (syntax + smoke) and `functions.Tests.ps1` (shared helpers). See [testing.md](testing.md).
