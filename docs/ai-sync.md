# AI sync

`scripts/sync-ai.ps1` aligns Claude Code, OpenCode, Codex, and Copilot across Windows and WSL: auth, settings, MCP servers, and skills.

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
| Skills | WSL `~/dotfiles/.agents/skills` | `~/winconf/.agents/skills`, linked Windows agent skill paths |

Current MCP: `context7` via `npx @upstash/context7-mcp`.

## Paths

| Path | Role |
|---|---|
| WSL `~/dotfiles/.agents/skills` | source of truth for skills |
| Windows `~/winconf/.agents/skills` | mirrored canonical Windows skills |
| Windows `~/.agents` | junction to `~/winconf/.agents` for Codex and VS Code/Copilot-compatible agents |
| Windows `~/.claude/skills` | junction to canonical skills for Claude Code |
| Windows `~/.config/opencode/skills` | junction to canonical skills for OpenCode |
| Windows `~/.copilot/skills` | junction to canonical skills for Copilot |

Only WSL skill directories containing `SKILL.md` and listed in `$windowsSkillNames` are copied. GitHub skill sources are not fetched. Linux-only stacks such as Laravel and WordPress stay in WSL.

## Re-run after

- `claude login` or OAuth refresh.
- WSL `~/dotfiles/.agents/skills` changes.
- `$mcpServers` changes.
- New-machine bootstrap.

## Validation

Run `make test` or `Invoke-Pester -Path .\tests\sync-ai.Tests.ps1 -Output Detailed`.
