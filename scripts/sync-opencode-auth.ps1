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

$anthropicEntry = @{
    type    = "oauth"
    refresh = $oauth.refreshToken
    access  = $oauth.accessToken
    expires = $oauth.expiresAt
}

Write-Host "Read Claude Code credentials (expires $($oauth.expiresAt))" -ForegroundColor Green

function Update-AuthFile {
    param([string]$Path, [hashtable]$Entry)

    if (Test-Path $Path) {
        $auth = Get-Content $Path -Raw | ConvertFrom-Json
    } else {
        $parentDir = Split-Path $Path -Parent
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        $auth = [PSCustomObject]@{}
    }

    $auth | Add-Member -NotePropertyName "anthropic" -NotePropertyValue ([PSCustomObject]$Entry) -Force
    $auth | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}

Write-Host "Updating Windows opencode auth..." -ForegroundColor Cyan
Update-AuthFile -Path $winAuthPath -Entry $anthropicEntry
Write-Host "  $winAuthPath" -ForegroundColor DarkGray

Write-Host "Updating WSL opencode auth..." -ForegroundColor Cyan
$wslCheck = wsl bash -c "test -d ~/.local/share/opencode && echo exists" 2>$null
if ($wslCheck -eq "exists") {
    $jsonPayload = [PSCustomObject]$anthropicEntry | ConvertTo-Json -Depth 10 -Compress
    $tmpScript = New-TemporaryFile
    $winPath = $tmpScript.FullName -replace '\\', '/'
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
    $scriptContent -replace "`r`n", "`n" | Set-Content $tmpScript.FullName -NoNewline -Encoding UTF8
    $jsonPayload | wsl bash $wslTmpScript
    Remove-Item $tmpScript.FullName -Force
    Write-Host "  $wslAuthPath" -ForegroundColor DarkGray
} else {
    Write-Host "  WSL opencode directory not found, skipping." -ForegroundColor Yellow
}

Write-Host "Anthropic credentials synced to opencode." -ForegroundColor Green
