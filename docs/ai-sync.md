# AI sync

`scripts/sync-ai.ps1` keeps Claude Code and OpenCode aligned across Windows and WSL: auth, settings, MCP servers, and skills.

## Commands

| Task | Command |
|---|---|
| Sync all | `.\scripts\sync-ai.ps1` |
| Skip auth | `.\scripts\sync-ai.ps1 -SkipAuth` |
| Skip MCP | `.\scripts\sync-ai.ps1 -SkipMcp` |
| Skip skills | `.\scripts\sync-ai.ps1 -SkipSkills` |

The script runs with strict mode and stops on unexpected errors.

## Flow

| Step | Source | Destinations |
|---|---|---|
| Auth | `~/.claude/.credentials.json` | OpenCode auth on Windows and WSL |
| Settings | `$claudeSettings` in script | Claude settings on Windows and WSL |
| MCP | `$mcpServers` in script | `claude mcp` and OpenCode config |
| Skills | `$skillSources` URLs | `~/.agents/skills`, Claude skills, OpenCode skills |

Current MCP set: `context7` through `npx @upstash/context7-mcp`.

## Skill layout

| Path | Role |
|---|---|
| `~/.agents/skills` | canonical skill store |
| `~/.claude/skills` | Claude consumer copy |
| `~/.config/opencode/skills` | OpenCode consumer copy |
| `\\wsl$\<distro>\home\<user>\...` | WSL auth/settings targets |

Windows copies skill trees because some tools handle reparse points poorly. Leave existing symlink targets alone; do not introduce new ones.

## Configuration surface

| Name | Purpose |
|---|---|
| `$claudeCredPath` | Claude OAuth source |
| `$claudeSettingsPath` | Claude settings destination |
| `$winAuthPath` | Windows OpenCode auth destination |
| `$wslAuthPath` | WSL OpenCode auth destination |
| `$mcpServers` | ordered MCP server map |
| `$agentsSkillsDir` | canonical skill directory |
| `$skillSources` | GitHub tree URLs for skill subdirectories |

## Re-run when

- Claude OAuth changes after `claude login`.
- `$skillSources` changes.
- `$mcpServers` changes.
- A new machine has completed bootstrap.

## Validation

| Scope | Command |
|---|---|
| Full suite | `make test` |
| Sync suite | `Invoke-Pester -Path .\tests\sync-ai.Tests.ps1 -Output Detailed` |

The sync suite covers credential path resolution, MCP argument building, and skill-source parsing.
