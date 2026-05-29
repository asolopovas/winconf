# AI sync

`scripts/sync-ai.ps1` aligns Claude Code and OpenCode across Windows and WSL: auth, settings, MCP servers, and skills.

## Run

| Task | Command |
|---|---|
| All | `.\scripts\sync-ai.ps1` |
| Skip auth | `.\scripts\sync-ai.ps1 -SkipAuth` |
| Skip MCP | `.\scripts\sync-ai.ps1 -SkipMcp` |
| Skip skills | `.\scripts\sync-ai.ps1 -SkipSkills` |

Strict mode is enabled; unexpected errors stop the sync.

## Flow

| Step | Source | Destinations |
|---|---|---|
| Auth | `~/.claude/.credentials.json` | OpenCode Windows/WSL auth |
| Settings | `$claudeSettings` | Claude Windows/WSL settings |
| MCP | `$mcpServers` | `claude mcp`, OpenCode config |
| Skills | `$skillSources` | `~/.agents/skills`, Claude, OpenCode |

Current MCP: `context7` via `npx @upstash/context7-mcp`.

## Paths

| Path | Role |
|---|---|
| `~/.agents/skills` | canonical skills |
| `~/.claude/skills` | Claude copy |
| `~/.config/opencode/skills` | OpenCode copy |
| `\\wsl$\<distro>\home\<user>\...` | WSL targets |

Copy skills on Windows because some tools handle reparse points poorly. Leave existing symlinks; do not add new ones.

## Re-run after

- `claude login` or OAuth refresh.
- `$skillSources` changes.
- `$mcpServers` changes.
- New-machine bootstrap.

## Validation

Run `make test` or `Invoke-Pester -Path .\tests\sync-ai.Tests.ps1 -Output Detailed`.
