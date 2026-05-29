# Bootstrap

`init.ps1` is the elevated entry and must work locally and through remote `iwr | iex` before clone.

## Run

| Scope | Command |
|---|---|
| Local | `.\init.ps1` |
| Local plus apps | `.\init.ps1 -Software` |
| Remote | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1 | iex` |
| Remote plus apps | `iwr https://raw.githubusercontent.com/asolopovas/winconf/main/init-software.ps1 | iex` |

Transcript: `$env:TEMP\winconf.log`.

## Modes

| Mode | Trigger | Action |
|---|---|---|
| Fresh | repo missing | reset winget, install essentials, clone, fix ACLs, run setup |
| Update | repo exists | prompt, pull, upgrade available essentials, run setup |

## Order

`cleanup` -> `inst-paths` -> `paths-doctor` -> `inst-fonts` -> `inst-pwsh` -> `inst-terminal` -> `inst-ahk` -> `wsl-exclusions` -> `inst-modules` -> `inst-scoop` -> `inst-software` with `-Software` -> `inst-aimp-delete-helper`.

Add scripts only after prerequisites.

## Installer contract

- Run directly and repeatedly.
- Check state before work; reinstall only with `-Force`.
- Prefer exact winget IDs and noninteractive agreements.
- Re-check `Get-Command` after PATH edits.
- Use `CreateSymLink` for repo-managed config links.
- Avoid interactive profile dependencies.

## Update contract

- Upgrade only IDs in `winget upgrade` output.
- Pass `-Update` only to scripts that support it.
- Failures include command, package ID, path, and next action.

## Validation

Run `make test`. For bootstrap changes, state clean-VM/fresh-profile coverage or skipped reason.
