$claudeCredPath = Join-Path $env:USERPROFILE ".claude\.credentials.json"
$claudeSettingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
$winAuthPath = Join-Path $env:USERPROFILE ".local\share\opencode\auth.json"
$wslAuthPath = "~/.local/share/opencode/auth.json"

if (!(Test-Path $claudeCredPath)) {
    Write-Host "Claude Code credentials not found at $claudeCredPath" -ForegroundColor Red
    Write-Host "Run 'claude' and authenticate first." -ForegroundColor Yellow
    exit 1
}

$claude = Get-Content $claudeCredPath -Raw | ConvertFrom-Json
$oauth = $claude.claudeAiOauth

if (!$oauth) {
    Write-Host "No claudeAiOauth found in credentials file." -ForegroundColor Red
    exit 1
}

Write-Host "Read Claude Code credentials (expires $($oauth.expiresAt))" -ForegroundColor Green

# --- Claude settings sync ---
$claudeSettings = @{
    includeCoAuthoredBy = $false
    includeGitInstructions = $false
    attribution = @{
        commit = ""
        pr = ""
    }
}

function Sync-ClaudeSettings {
    param([string]$Path)

    if (Test-Path $Path) {
        $existing = Get-Content $Path -Raw | ConvertFrom-Json
    } else {
        $parentDir = Split-Path $Path -Parent
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        $existing = [PSCustomObject]@{}
    }

    foreach ($key in $claudeSettings.Keys) {
        $existing | Add-Member -NotePropertyName $key -NotePropertyValue $claudeSettings[$key] -Force
    }

    $json = ($existing | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
    if (!$json.EndsWith("`n")) { $json += "`n" }
    [System.IO.File]::WriteAllText($Path, $json)
}

Write-Host "Syncing Claude settings (Windows)..." -ForegroundColor Cyan
Sync-ClaudeSettings -Path $claudeSettingsPath
Write-Host "  $claudeSettingsPath" -ForegroundColor DarkGray

# --- Auth sync ---
function Update-AuthFile {
    param([string]$Path, [string]$AccessToken, [string]$RefreshToken, [long]$ExpiresAt)

    if (Test-Path $Path) {
        $auth = Get-Content $Path -Raw | ConvertFrom-Json
    } else {
        $parentDir = Split-Path $Path -Parent
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        $auth = [PSCustomObject]@{}
    }

    $entry = [ordered]@{
        type    = "oauth"
        access  = $AccessToken
        refresh = $RefreshToken
        expires = $ExpiresAt
    }
    $auth | Add-Member -NotePropertyName "anthropic" -NotePropertyValue ([PSCustomObject]$entry) -Force
    $json = ($auth | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
    if (!$json.EndsWith("`n")) { $json += "`n" }
    [System.IO.File]::WriteAllText($Path, $json)
}

Write-Host "Updating Windows opencode auth..." -ForegroundColor Cyan
Update-AuthFile -Path $winAuthPath -AccessToken $oauth.accessToken -RefreshToken $oauth.refreshToken -ExpiresAt $oauth.expiresAt
Write-Host "  $winAuthPath" -ForegroundColor DarkGray

Write-Host "Updating WSL (opencode auth + Claude settings)..." -ForegroundColor Cyan
$wslCheck = wsl bash -c "test -d ~/.local/share/opencode && echo exists" 2>$null
if ($wslCheck -eq "exists") {
    $jsonPayload = "{""type"":""oauth"",""access"":""$($oauth.accessToken)"",""refresh"":""$($oauth.refreshToken)"",""expires"":$($oauth.expiresAt)}"
    $settingsJson = ($claudeSettings | ConvertTo-Json -Depth 10 -Compress) -replace '"', '\"'
    $tmpScript = [System.IO.Path]::GetTempFileName()
    $winPath = $tmpScript -replace '\\', '/'
    $wslTmpScript = wsl wslpath -u "$winPath"
    $scriptContent = @'
#!/bin/bash
authpath=~/.local/share/opencode/auth.json
claudedir=~/.claude
claudesettings="$claudedir/settings.json"
tmpfile=$(mktemp)
read -r jsonpayload
jsonpayload=$(echo "$jsonpayload" | tr -d '\r')
read -r settingspayload
settingspayload=$(echo "$settingspayload" | tr -d '\r')

# Sync opencode auth
if [ -f "$authpath" ]; then
    cp "$authpath" "$tmpfile"
else
    mkdir -p ~/.local/share/opencode
    echo '{}' > "$tmpfile"
fi
jq --argjson entry "$jsonpayload" '.anthropic = $entry' "$tmpfile" > "${tmpfile}.out" && mv "${tmpfile}.out" "$tmpfile"
mv "$tmpfile" "$authpath"
chmod 600 "$authpath"

# Sync Claude settings
mkdir -p "$claudedir"
if [ -f "$claudesettings" ]; then
    tmpset=$(mktemp)
    jq --argjson s "$settingspayload" '. * $s' "$claudesettings" > "$tmpset" && mv "$tmpset" "$claudesettings"
else
    echo "$settingspayload" | jq '.' > "$claudesettings"
fi
chmod 600 "$claudesettings"
'@
    [System.IO.File]::WriteAllText($tmpScript, ($scriptContent -replace "`r`n", "`n"))
    "$jsonPayload`n$settingsJson" | wsl bash $wslTmpScript
    Remove-Item $tmpScript -Force
    Write-Host "  $wslAuthPath" -ForegroundColor DarkGray
    Write-Host "  ~/.claude/settings.json" -ForegroundColor DarkGray
} else {
    Write-Host "  WSL opencode directory not found, skipping." -ForegroundColor Yellow
}

Write-Host "Anthropic credentials and Claude settings synced." -ForegroundColor Green
