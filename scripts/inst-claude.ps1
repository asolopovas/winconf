$claudeDir = "$env:USERPROFILE\.claude"

if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir | Out-Null
}

npm install -g @anthropic-ai/claude-code

$settings = @{
    includeCoAuthoredBy    = $false
    includeGitInstructions = $false
} | ConvertTo-Json

Set-Content -Path "$claudeDir\settings.json" -Value $settings -Encoding UTF8

Write-Host "Claude Code installation complete!" -ForegroundColor Green
