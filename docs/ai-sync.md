# AI sync

`scripts/sync-ai.ps1` aligns Claude Code and OpenCode across Windows and WSL: auth, settings, MCP servers, and skills.

## Run

| Task | Command |
|---|---|
| All | `.\scripts\sync-ai.ps1` |
| Skip auth | `.\scripts\sync-ai.ps1 -SkipAuth` |
| Skip MCP | `.\scripts\sync-ai.ps1 -SkipMcp` |
| Skip skills | `.\scripts\sync-ai.ps1 -SkipSkills` |

Strict mode stops unexpected errors.

## Flow

| Step | Source | Destinations |
|---|---|---|
| Auth | `~/.claude/.credentials.json` | OpenCode Windows/WSL auth |
| Settings | `$claudeSettings` | Claude Windows/WSL settings |
| MCP | `$mcpServers` | `claude mcp`, OpenCode config |
| Skills | WSL `~/dotfiles/.agents/skills` | Windows `~/.agents/skills`, Claude, OpenCode |

Current MCP: `context7` via `npx @upstash/context7-mcp`.

## Paths

| Path | Role |
|---|---|
| WSL `~/dotfiles/.agents/skills` | source of truth for skills |
| Windows `~/.agents/skills` | mirrored canonical skills |
| Windows `~/.claude/skills` | junction to canonical skills |
| Windows `~/.config/opencode/skills` | junction to canonical skills |

Only WSL skill directories containing `SKILL.md` are copied. GitHub skill sources are not fetched.

## Re-run after

- `claude login` or OAuth refresh.
- WSL `~/dotfiles/.agents/skills` changes.
- `$mcpServers` changes.
- New-machine bootstrap.

## Validation

Run `make test` or `Invoke-Pester -Path .\tests\sync-ai.Tests.ps1 -Output Detailed`.
