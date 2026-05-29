# Bootstrap

`init.ps1` is the admin entry point. It must also work through remote `iwr | iex`, before the repo is cloned.

## Invocation

| Mode | Command |
|---|---|
| Fresh install or update | `.\init.ps1` |
| Include extended apps | `.\init.ps1 -Software` |
| Remote install | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Remote install with extended apps | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init-software.ps1 | iex` |

Requires elevated PowerShell. Transcript path: `$env:TEMP\winconf.log`.

## Modes

| Mode | Trigger | Behavior |
|---|---|---|
| Fresh | `$env:USERPROFILE\winconf` missing | reset winget sources, install Git, install essentials, clone repo, fix ACLs, run setup scripts |
| Update | repo exists | prompt, `git pull`, upgrade essential winget IDs with available updates, run setup scripts |

## Bootstrap constants

| Name | Meaning |
|---|---|
| `$DOTFILES` | canonical repo root |
| `$SCRIPTS_DIR` | setup script directory |
| `$REPO_URL` | Git remote |
| `$AUTOHOTKEYVERSION` | version passed to `inst-ahk.ps1` |
| `$ESSENTIAL_SOFTWARE` | winget IDs installed on fresh run and upgraded on update |
| `$PINNED_SOFTWARE` | winget IDs pinned after setup |
| `$SOURCE_FILES` | ordered setup scripts, without `.ps1` |

## Source order

Current order:

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
11. `inst-software` when `-Software` is set
12. `inst-aimp-delete-helper`

Order is part of the contract. Add a script only where its prerequisites are already satisfied.

## Installer contract

Every `scripts/inst-*.ps1` must:

- Be runnable directly.
- Be safe when run repeatedly.
- Check existing state before install work.
- Reinstall only with explicit `-Force`.
- Prefer winget exact IDs and noninteractive agreements.
- Re-check `Get-Command` after PATH-changing installers.
- Use `CreateSymLink` for repo-managed config links.
- Avoid assuming the interactive profile has loaded.

## Update contract

- Do not reinstall essentials blindly.
- Upgrade only IDs present in `winget upgrade` output.
- Pass `-Update` only to setup scripts that support it.
- Keep failures actionable with command, package ID, and path context.

## Validation

Run `make test`. For bootstrap changes, also state whether a clean VM or fresh user-profile run was performed.
