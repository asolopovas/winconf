# Bootstrap

`init.ps1` is the elevated entry and must work through remote `iwr | iex` before clone.

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

Add scripts only after prerequisites.

## Installer contract

- Run directly and repeatedly.
- Check state before work.
- Reinstall only with `-Force`.
- Prefer exact winget IDs and noninteractive agreements.
- Re-check `Get-Command` after PATH edits.
- Use `CreateSymLink` for repo-managed config links.
- Avoid interactive profile dependencies.

## Update contract

- Upgrade only IDs present in `winget upgrade` output.
- Pass `-Update` only to scripts that support it.
- Include command, package ID, path, and next action in failures.

## Validation

Run `make test`. For bootstrap changes, state clean-VM or fresh-profile coverage, or say it was skipped.
