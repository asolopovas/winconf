[CmdletBinding()]
param(
    [string]$SourceAlias = "router",
    [string]$TargetAlias = "nas-admin",
    [string]$RemoteCertPath = "",
    [string]$RemoteKeyPath = "",
    [string]$RemoteChainPath = "",
    [string]$InstallDir = "/share/Public/cert-sync",
    [string]$CronSchedule = "17 4 * * *",
    [string]$IdentityPath = "$env:USERPROFILE\.ssh\id_cert_sync",
    [switch]$InstallSourceAuthorizedKey,
    [switch]$SkipInitialSync,
    [switch]$ForceKey
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Read-Required([string]$Name, [string]$Value, [string]$Prompt) {
    if (-not [string]::IsNullOrWhiteSpace($Value)) { return $Value }
    $answer = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($answer)) { throw "$Name is required" }
    return $answer.Trim()
}

function ConvertTo-ShLiteral([string]$Value) {
    if ($Value.Contains("'")) { throw "Value contains single quote and cannot be safely quoted: $Value" }
    return "'$Value'"
}

function Get-SshConfigValue([string]$Alias, [string]$Key) {
    $output = @(cmd /c "ssh -G $Alias 2>NUL")
    if ($LASTEXITCODE -ne 0) { throw "Cannot read ssh config for '$Alias'" }
    $line = @($output | Where-Object { $_ -match "^$Key\s+" } | Select-Object -First 1)
    if ($line.Count -eq 0) { throw "Cannot read ssh config value '$Key' for '$Alias'" }
    return ($line[0] -replace "^$Key\s+", "").Trim()
}

function Invoke-Native([string]$FilePath, [string[]]$Arguments) {
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FilePath failed with exit code $LASTEXITCODE" }
}

function Assert-KeyPair([string]$PrivateKeyPath) {
    $publicKeyPath = "$PrivateKeyPath.pub"
    if ($ForceKey) {
        Remove-Item -LiteralPath $PrivateKeyPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $publicKeyPath -Force -ErrorAction SilentlyContinue
    }
    if ((Test-Path -LiteralPath $PrivateKeyPath) -and (Test-Path -LiteralPath $publicKeyPath)) { return }
    $dir = Split-Path -Parent $PrivateKeyPath
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $comment = "cert-sync@$env:COMPUTERNAME"
    Invoke-Native "ssh-keygen" @("-t", "ed25519", "-C", $comment, "-f", $PrivateKeyPath, "-N", '""')
}

function Install-SourceKey([string]$PublicKey) {
    $pub = ConvertTo-ShLiteral $PublicKey
    $script = @'
pub=__PUB_LITERAL__
umask 077
for dir in "$HOME/.ssh" /jffs/.ssh /root/.ssh; do
    mkdir -p "$dir" 2>/dev/null || true
    touch "$dir/authorized_keys" 2>/dev/null || true
    if [ -f "$dir/authorized_keys" ]; then
        grep -qxF "$pub" "$dir/authorized_keys" 2>/dev/null || echo "$pub" >> "$dir/authorized_keys"
        chmod 600 "$dir/authorized_keys" 2>/dev/null || true
    fi
done
if command -v nvram >/dev/null 2>&1; then
    old=$(nvram get sshd_authkeys 2>/dev/null || true)
    if ! printf '%s\n' "$old" | grep -qxF "$pub" 2>/dev/null; then
        if [ -n "$old" ]; then
            new=$(printf '%s\n%s\n' "$old" "$pub")
        else
            new=$(printf '%s\n' "$pub")
        fi
        nvram set sshd_authkeys="$new" >/dev/null 2>&1 || true
        nvram commit >/dev/null 2>&1 || true
    fi
    service restart_sshd >/dev/null 2>&1 || true
fi
echo authorized
'@
    $script = $script.Replace("__PUB_LITERAL__", $pub)
    $tmp = [System.IO.Path]::GetTempFileName()
    Write-Utf8NoBom $tmp $script
    try {
        cmd /c "type `"$tmp`" | ssh $SourceAlias sh -s"
        if ($LASTEXITCODE -ne 0) { throw "ssh failed with exit code $LASTEXITCODE" }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) { throw "ssh was not found in PATH" }
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) { throw "scp was not found in PATH" }
if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) { throw "ssh-keygen was not found in PATH" }

$RemoteCertPath = Read-Required "RemoteCertPath" $RemoteCertPath "Remote fullchain/cert path on cert source"
$RemoteKeyPath = Read-Required "RemoteKeyPath" $RemoteKeyPath "Remote private key path on cert source"
if (-not $PSBoundParameters.ContainsKey("RemoteChainPath")) {
    $RemoteChainPath = (Read-Host "Remote chain path on cert source, or blank if fullchain includes it").Trim()
}

$identity = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($IdentityPath)
Assert-KeyPair $identity
$publicKey = (Get-Content -LiteralPath "$identity.pub" -Raw).Trim()

if ($InstallSourceAuthorizedKey) {
    Install-SourceKey $publicKey
}
else {
    Write-Host "[WARN] Add this public key to the certificate source before first sync:" -ForegroundColor Yellow
    Write-Host $publicKey
}

$sourceHost = Get-SshConfigValue $SourceAlias "hostname"
$sourceUser = Get-SshConfigValue $SourceAlias "user"
$sourcePort = Get-SshConfigValue $SourceAlias "port"

$syncScript = @'
#!/bin/sh
set -eu
umask 077
BASE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONF="$BASE_DIR/cert-sync.conf"
[ -r "$CONF" ] || { echo "missing config: $CONF" >&2; exit 1; }
. "$CONF"
LOG_PREFIX=${LOG_PREFIX:-cert-sync}
SSH_KEY=${SSH_KEY:-$BASE_DIR/.ssh/source_key}
KNOWN_HOSTS=${KNOWN_HOSTS:-$BASE_DIR/.ssh/known_hosts}
BACKUP_DIR=${BACKUP_DIR:-$BASE_DIR/backups}
CURRENT_DIR=${CURRENT_DIR:-$BASE_DIR/current}
SOURCE_PORT=${SOURCE_PORT:-22}
SOURCE_CHAIN_PATH=${SOURCE_CHAIN_PATH:-}
REMOTE="$SOURCE_USER@$SOURCE_HOST"
SSH_OPTS="-i $SSH_KEY -p $SOURCE_PORT -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=$KNOWN_HOSTS"
log() { printf '%s %s %s\n' "$(date '+%F %T')" "$LOG_PREFIX" "$*"; }
require_file() { [ -s "$1" ] || { log "required file missing or empty: $1"; exit 1; }; }
remote_copy() { ssh $SSH_OPTS "$REMOTE" "cat '$1'" > "$2"; }
restart_service() { [ -x "$1" ] && "$1" restart >/dev/null 2>&1 || true; }
TMP_DIR=$(mktemp -d /tmp/cert-sync.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM
mkdir -p "$BACKUP_DIR" "$CURRENT_DIR" "$BASE_DIR/.ssh"
chmod 700 "$BASE_DIR/.ssh"
remote_copy "$SOURCE_CERT_PATH" "$TMP_DIR/source-cert.pem"
remote_copy "$SOURCE_KEY_PATH" "$TMP_DIR/source-key.pem"
require_file "$TMP_DIR/source-cert.pem"
require_file "$TMP_DIR/source-key.pem"
awk 'BEGIN{p=0} /-----BEGIN CERTIFICATE-----/{p=1} p{print} /-----END CERTIFICATE-----/{exit}' "$TMP_DIR/source-cert.pem" > "$TMP_DIR/leaf.pem"
awk 'BEGIN{n=0} /-----BEGIN CERTIFICATE-----/{n++} n>1{print}' "$TMP_DIR/source-cert.pem" > "$TMP_DIR/chain.pem"
if [ -n "$SOURCE_CHAIN_PATH" ]; then
    remote_copy "$SOURCE_CHAIN_PATH" "$TMP_DIR/chain.pem" || true
fi
require_file "$TMP_DIR/leaf.pem"
CERT_PUB=$(openssl x509 -in "$TMP_DIR/leaf.pem" -pubkey -noout)
KEY_PUB=$(openssl pkey -in "$TMP_DIR/source-key.pem" -pubout 2>/dev/null || openssl rsa -in "$TMP_DIR/source-key.pem" -pubout 2>/dev/null)
[ "$CERT_PUB" = "$KEY_PUB" ] || { log "certificate and private key do not match"; exit 1; }
if [ -f /etc/stunnel/stunnel.pem ] && cmp -s "$TMP_DIR/leaf.pem" "$CURRENT_DIR/cert.pem" 2>/dev/null && cmp -s "$TMP_DIR/source-key.pem" "$CURRENT_DIR/privkey.pem" 2>/dev/null && cmp -s "$TMP_DIR/chain.pem" "$CURRENT_DIR/chain.pem" 2>/dev/null; then
    log "certificate unchanged"
    exit 0
fi
STAMP=$(date '+%Y%m%d-%H%M%S')
[ -f /etc/stunnel/stunnel.pem ] && cp /etc/stunnel/stunnel.pem "$BACKUP_DIR/stunnel.pem.$STAMP"
[ -f /etc/stunnel/uca.pem ] && cp /etc/stunnel/uca.pem "$BACKUP_DIR/uca.pem.$STAMP"
cat "$TMP_DIR/leaf.pem" "$TMP_DIR/source-key.pem" > /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem
if [ -s "$TMP_DIR/chain.pem" ]; then
    cp "$TMP_DIR/chain.pem" /etc/stunnel/uca.pem
    chmod 600 /etc/stunnel/uca.pem
fi
cp "$TMP_DIR/leaf.pem" "$CURRENT_DIR/cert.pem"
cp "$TMP_DIR/source-key.pem" "$CURRENT_DIR/privkey.pem"
cp "$TMP_DIR/chain.pem" "$CURRENT_DIR/chain.pem"
cat "$TMP_DIR/leaf.pem" "$TMP_DIR/chain.pem" > "$CURRENT_DIR/fullchain.pem"
chmod 600 "$CURRENT_DIR"/*.pem
restart_service /etc/init.d/Qthttpd.sh
restart_service /etc/init.d/thttpd.sh
restart_service /etc/init.d/stunnel.sh
[ -x "$BASE_DIR/post-install.sh" ] && "$BASE_DIR/post-install.sh" "$CURRENT_DIR/cert.pem" "$CURRENT_DIR/privkey.pem" "$CURRENT_DIR/fullchain.pem" || true
log "certificate installed"
'@

$config = @"
SOURCE_HOST=$(ConvertTo-ShLiteral $sourceHost)
SOURCE_USER=$(ConvertTo-ShLiteral $sourceUser)
SOURCE_PORT=$(ConvertTo-ShLiteral $sourcePort)
SOURCE_CERT_PATH=$(ConvertTo-ShLiteral $RemoteCertPath)
SOURCE_KEY_PATH=$(ConvertTo-ShLiteral $RemoteKeyPath)
SOURCE_CHAIN_PATH=$(ConvertTo-ShLiteral $RemoteChainPath)
SSH_KEY=$(ConvertTo-ShLiteral "$InstallDir/.ssh/source_key")
BACKUP_DIR=$(ConvertTo-ShLiteral "$InstallDir/backups")
LOG_PREFIX='cert-sync'
"@

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cert-sync-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmpRoot | Out-Null
try {
    $scriptPath = Join-Path $tmpRoot "sync-cert.sh"
    $configPath = Join-Path $tmpRoot "cert-sync.conf"
    Write-Utf8NoBom $scriptPath $syncScript
    Write-Utf8NoBom $configPath $config
    Invoke-Native "scp" @($scriptPath, "$TargetAlias`:/tmp/sync-cert.sh")
    Invoke-Native "scp" @($configPath, "$TargetAlias`:/tmp/cert-sync.conf")
    Invoke-Native "scp" @($identity, "$TargetAlias`:/tmp/source_key")
    $dir = ConvertTo-ShLiteral $InstallDir
    $cron = ConvertTo-ShLiteral "$CronSchedule $InstallDir/sync-cert.sh >> $InstallDir/sync.log 2>&1"
    $marker = ConvertTo-ShLiteral "$InstallDir/sync-cert.sh"
    $remote = "mkdir -p $dir $dir/.ssh $dir/backups $dir/current; mv /tmp/sync-cert.sh $dir/sync-cert.sh; mv /tmp/cert-sync.conf $dir/cert-sync.conf; mv /tmp/source_key $dir/.ssh/source_key; chmod 700 $dir/.ssh; chmod 755 $dir/sync-cert.sh; chmod 600 $dir/cert-sync.conf $dir/.ssh/source_key; touch /etc/config/crontab; grep -vF $marker /etc/config/crontab > /tmp/cert-sync.crontab || true; echo $cron >> /tmp/cert-sync.crontab; cat /tmp/cert-sync.crontab > /etc/config/crontab; crontab /etc/config/crontab; /etc/init.d/crond.sh restart >/dev/null 2>&1 || true"
    Invoke-Native "ssh" @($TargetAlias, $remote)
    if (-not $SkipInitialSync) {
        Invoke-Native "ssh" @($TargetAlias, "$InstallDir/sync-cert.sh")
    }
}
finally {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "[OK] installed $InstallDir"
