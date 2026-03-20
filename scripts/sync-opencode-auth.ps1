$claudeCredPath = Join-Path $env:USERPROFILE ".claude\.credentials.json"
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

function Update-AuthFile {
    param([string]$Path, [string]$AccessToken, [string]$RefreshToken, [long]$ExpiresAt)

    if (Test-Path $Path) {
        $raw = Get-Content $Path -Raw
    } else {
        $parentDir = Split-Path $Path -Parent
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        $raw = '{}'
    }

    $pyScript = @"
import sys, json
auth = json.loads(sys.stdin.read())
auth['anthropic'] = {
    'type': 'oauth',
    'access': sys.argv[1],
    'refresh': sys.argv[2],
    'expires': int(sys.argv[3])
}
with open(sys.argv[4], 'w', newline='\n') as f:
    json.dump(auth, f, indent=2)
    f.write('\n')
"@
    $raw | python -c $pyScript $AccessToken $RefreshToken $ExpiresAt $Path
}

Write-Host "Updating Windows opencode auth..." -ForegroundColor Cyan
Update-AuthFile -Path $winAuthPath -AccessToken $oauth.accessToken -RefreshToken $oauth.refreshToken -ExpiresAt $oauth.expiresAt
Write-Host "  $winAuthPath" -ForegroundColor DarkGray

Write-Host "Updating WSL opencode auth..." -ForegroundColor Cyan
$wslCheck = wsl bash -c "test -d ~/.local/share/opencode && echo exists" 2>$null
if ($wslCheck -eq "exists") {
    $jsonPayload = "{""type"":""oauth"",""access"":""$($oauth.accessToken)"",""refresh"":""$($oauth.refreshToken)"",""expires"":$($oauth.expiresAt)}"
    $tmpScript = [System.IO.Path]::GetTempFileName()
    $winPath = $tmpScript -replace '\\', '/'
    $wslTmpScript = wsl wslpath -u "$winPath"
    $scriptContent = @'
#!/bin/bash
authpath=~/.local/share/opencode/auth.json
tmpfile=$(mktemp)
read -r jsonpayload
jsonpayload=$(echo "$jsonpayload" | tr -d '\r')
if [ -f "$authpath" ]; then
    cp "$authpath" "$tmpfile"
else
    mkdir -p ~/.local/share/opencode
    echo '{}' > "$tmpfile"
fi
echo "$jsonpayload" | python3 -c '
import sys, json
entry = json.load(sys.stdin)
with open(sys.argv[1], "r") as f:
    auth = json.load(f)
auth["anthropic"] = entry
with open(sys.argv[1], "w") as f:
    json.dump(auth, f, indent=2)
' "$tmpfile"
mv "$tmpfile" "$authpath"
chmod 600 "$authpath"
'@
    [System.IO.File]::WriteAllText($tmpScript, ($scriptContent -replace "`r`n", "`n"))
    $jsonPayload | wsl bash $wslTmpScript
    Remove-Item $tmpScript -Force
    Write-Host "  $wslAuthPath" -ForegroundColor DarkGray
} else {
    Write-Host "  WSL opencode directory not found, skipping." -ForegroundColor Yellow
}

Write-Host "Anthropic credentials synced to opencode." -ForegroundColor Green
