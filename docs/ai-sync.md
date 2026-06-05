# AI sync

`scripts/sync-ai.ps1` aligns Claude Code, OpenCode, Codex, Copilot, and Pi across Windows and WSL: auth, settings, MCP servers, skills, and prompts.

## Run

| Task | Command |
|---|---|
| All | `.\scripts\sync-ai.ps1` |
| Install/update Codex | `.\scripts\inst-cdx.ps1` |
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
| Prompts | `~/winconf/.agents/prompts` | Windows `~/.pi/agent/prompts`, `~/.claude/commands`, `~/.config/opencode/commands`, `~/.opencode/commands` junctions; Codex `~/.codex/prompts` and `~/.codex/commands` hard links |
| Agent definitions | `~/winconf/.agents/agents/{codex,claude,opencode}` | Windows tool-specific agent directories |
| Pi config | `~/winconf/.agents/pi/settings.json`, `~/winconf/.agents/pi/npm/package.json` | Windows `~/.pi/agent` symlinks |

Current MCP: `context7` via `npx @upstash/context7-mcp`.

## Paths

| Path | Role |
|---|---|
| WSL `~/dotfiles/.agents/skills` | source of truth for skills |
| Windows `~/winconf/.agents` | canonical Windows agent config root |
| Windows `~/winconf/.agents/skills` | mirrored canonical Windows skills |
| Windows `~/winconf/.agents/prompts` | canonical prompt files such as `/gw` and `/doc-refactor` |
| Windows `~/winconf/.agents/agents/codex` | canonical Codex custom agent `.toml` files |
| Windows `~/winconf/.agents/agents/claude` | canonical Claude Code subagent `.md` files |
| Windows `~/winconf/.agents/agents/opencode` | canonical OpenCode agent `.md` files |
| Windows `~/winconf/.agents/pi` | canonical Pi settings and extension package config |
| Windows `~/.agents` | junction to `~/winconf/.agents` for Codex and VS Code/Copilot-compatible agents |
| Windows `~/.pi/agent/prompts` | junction to canonical prompt files for Pi |
| Windows `~/.codex/prompts/*.md` | hard links to canonical Codex prompt files; invoke as `/prompts:name` |
| Windows `~/.codex/commands/*.md` | hard links to canonical Codex command files when supported by the installed Codex version |
| Windows `~/.claude/commands` | junction to canonical prompt files for Claude Code commands |
| Windows `~/.config/opencode/commands` | junction to canonical prompt files for OpenCode commands |
| Windows `~/.opencode/commands` | compatibility junction to canonical prompt files for OpenCode commands |
| Windows `~/.codex/agents` | junction to canonical Codex custom agents |
| Windows `~/.claude/agents` | junction to canonical Claude Code subagents |
| Windows `~/.config/opencode/agents` | junction to canonical OpenCode agents |
| Windows `~/.config/opencode/agent` | compatibility junction to canonical OpenCode agents |
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
