$ErrorActionPreference = "Stop"
$root = Join-Path $env:USERPROFILE "winconf"
. (Join-Path $root "functions.ps1")

$claudeDir = Join-Path $env:USERPROFILE ".claude"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

npm install -g @anthropic-ai/claude-code
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Dotfile-manage settings.json: symlink it into the winconf repo (mirrors the WSL
# dotfiles pattern where ~/.claude/settings.json -> ~/dotfiles/.claude/settings.json).
CreateSymLink (Join-Path $claudeDir "settings.json") (Join-Path $root ".claude\settings.json") | Out-Null

Write-Host "Claude Code installation complete" -ForegroundColor Green
