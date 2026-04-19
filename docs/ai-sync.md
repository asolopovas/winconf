## AI Sync (`scripts/sync-ai.ps1`)

Keeps Claude Code and OpenCode aligned on Windows: OAuth credentials, settings, MCP servers, and skills. Mirrors the bash `sync-ai.sh` from the Linux dotfiles.

### Commands

```powershell
.\scripts\sync-ai.ps1                  # sync everything (auth + MCP + skills)
.\scripts\sync-ai.ps1 -SkipAuth        # skip credential propagation
.\scripts\sync-ai.ps1 -SkipMcp         # skip MCP server registration
.\scripts\sync-ai.ps1 -SkipSkills      # skip skill install/copy
```

Runs with `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` — any unexpected failure aborts the sync.

### What it does

1. **Auth** — reads `~/.claude/.credentials.json`, writes matching `auth.json` to OpenCode on Windows (`~\.local\share\opencode\auth.json`) and WSL (`~/.local/share/opencode/auth.json`).
2. **Settings** — pushes opinionated `$claudeSettings` (disable co-authored-by / git instructions / attribution) into `~/.claude/settings.json`, Windows + WSL.
3. **MCP** — registers every entry in `$mcpServers` with `claude mcp` and writes the OpenCode config JSON. Current set: `context7` via `npx @upstash/context7-mcp`.
4. **Skills** — installs every URL in `$skillSources` to `~/.agents/skills`, then copies the resulting dirs into `~/.claude/skills` and `~/.config/opencode/skills`.

### Layout (canonical → consumers)

| CLI | Path | How it reads |
|---|---|---|
| Claude Code | `~/.claude/skills` | Copied from `~/.agents/skills` |
| OpenCode | `~/.config/opencode/skills` | Copied from `~/.agents/skills` |
| WSL Claude / OpenCode | `\\wsl$\<distro>\home\<user>\...` | Auth + settings pushed during the same run |

Unlike the Linux setup (which uses symlinks), Windows copies the skill trees because some tools don't follow reparse points cleanly. If a skill target ends up as a symlink to the canonical dir, leave it — just don't introduce new symlink paths.

### Configuration surface

| Var / path | Purpose |
|---|---|
| `$claudeCredPath` | `~/.claude/.credentials.json` — source of truth for OAuth |
| `$claudeSettingsPath` | `~/.claude/settings.json` — overwritten with `$claudeSettings` |
| `$winAuthPath` / `$wslAuthPath` | OpenCode auth destinations |
| `$mcpServers` | `[ordered]` map of MCP server id → command args |
| `$agentsSkillsDir` | `~/.agents/skills` — canonical skill store |
| `$skillSources` | Array of GitHub `tree/<branch>/path` URLs; installer extracts that subdir |

### Tests

`tests/sync-ai.Tests.ps1` covers credential path resolution, MCP server argument building, and skill-source parsing. Run the whole suite with `make test` or just this file:

```powershell
Invoke-Pester -Path .\tests\sync-ai.Tests.ps1 -Output Detailed
```

### When to re-run

- After `claude login` / new OAuth refresh — run to propagate to OpenCode and WSL.
- After editing `$skillSources` or `$mcpServers` — re-run with the matching `-Skip*` switches unset.
- After a fresh `init.ps1` on a new machine — runs as part of the provisioning follow-up.
