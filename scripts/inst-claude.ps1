$ErrorActionPreference = "Stop"
$claudeDir = Join-Path $env:USERPROFILE ".claude"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

npm install -g @anthropic-ai/claude-code
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$settings = @{
    includeCoAuthoredBy    = $false
    includeGitInstructions = $false
} | ConvertTo-Json -Depth 5

Set-Content -Path (Join-Path $claudeDir "settings.json") -Value $settings -Encoding UTF8
Write-Host "Claude Code installation complete" -ForegroundColor Green
