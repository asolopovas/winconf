# Bootstrap

`init.ps1` is the elevated entry point and must work through remote `iwr | iex` before clone.

## Run

| Scope | Command |
|---|---|
| Local | `.\init.ps1` |
| Local plus extended apps | `.\init.ps1 -Software` |
| Remote | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Remote plus extended apps | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init-software.ps1 | iex` |

Transcript: `$env:TEMP\winconf.log`.

## Modes

| Mode | Trigger | Behavior |
|---|---|---|
| Fresh | repo missing | reset winget sources, install Git and essentials, clone, fix ACLs, run setup order |
| Update | repo exists | prompt, pull, upgrade available essentials, run setup order |

## Constants

| Name | Meaning |
|---|---|
| `$DOTFILES` | repo root |
| `$SCRIPTS_DIR` | setup script directory |
| `$REPO_URL` | Git remote |
| `$AUTOHOTKEYVERSION` | value passed to `inst-ahk.ps1` |
| `$ESSENTIAL_SOFTWARE` | fresh install and update winget IDs |
| `$PINNED_SOFTWARE` | winget pins |
| `$SOURCE_FILES` | ordered setup scripts without `.ps1` |

## Setup order

1. `cleanup`
2. `inst-paths`
3. `paths-doctor`
4. `inst-fonts`
5. `inst-pwsh`
6. `inst-terminal`
7. `inst-ahk`
8. `wsl-exclusions`
9. `inst-modules`
10. `inst-scoop`
11. `inst-software` with `-Software`
12. `inst-aimp-delete-helper`

Add scripts only after their prerequisites.

## Installer contract

Every `scripts/inst-*.ps1` must:

- Run directly and repeatedly.
- Check existing state before work.
- Reinstall only with `-Force`.
- Prefer exact winget IDs with noninteractive agreements.
- Re-check `Get-Command` after PATH changes.
- Use `CreateSymLink` for repo-managed config links.
- Avoid depending on the interactive profile.

## Update contract

- Upgrade only IDs present in `winget upgrade` output.
- Pass `-Update` only to scripts that support it.
- Make failures actionable with command, package ID, and path context.

## Validation

Run `make test`. For bootstrap changes, state clean-VM/fresh-profile coverage or that it was skipped.
