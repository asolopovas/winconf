[CmdletBinding()]
param(
    [string]$RouterHost = "192.168.1.1",
    [string]$RouterUser = "asolopovas",
    [int]$RouterPort = 33133,
    [string]$NasHost = "192.168.1.100",
    [string]$NasUser = "admin",
    [int]$NasPort = 990,
    [string]$RouterCertPath = "/jffs/.le/agreen.ddns.net_ecc/fullchain.cer",
    [string]$RouterKeyPath = "/jffs/.le/agreen.ddns.net_ecc/domain.key",
    [string]$RouterChainPath = "/jffs/.le/agreen.ddns.net_ecc/ca.cer",
    [string]$NasInstallDir = "/share/Public/router-cert-sync",
    [string]$CronSchedule = "17 4 * * *",
    [string]$RouterIdentityPath = "$env:USERPROFILE\.ssh\id_rsa",
    [switch]$InstallRouterAuthorizedKey,
    [switch]$SkipInitialSync,
    [switch]$Force
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$script:RouterKeyInstalled = $false

function Write-Step([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Write-OK([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-WarnLine([string]$Message) {
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Write-FailLine([string]$Message) {
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Assert-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name was not found in PATH"
    }
}

function Invoke-Native([string]$FilePath, [string[]]$Arguments, [switch]$AllowFailure) {
    & $FilePath @Arguments | ForEach-Object { Write-Host $_ }
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "$FilePath failed with exit code $exitCode"
    }
    return $exitCode
}

function Invoke-Ssh([string]$Target, [int]$Port, [string]$Command, [switch]$AllowFailure) {
    $args = @("-p", [string]$Port, $Target, $Command)
    return Invoke-Native -FilePath "ssh" -Arguments $args -AllowFailure:$AllowFailure
}

function Copy-Scp([string]$Source, [string]$Target, [int]$Port) {
    $args = @("-P", [string]$Port, $Source, $Target)
    Invoke-Native -FilePath "scp" -Arguments $args | Out-Null
}

function ConvertTo-ShLiteral([string]$Value) {
    if ($Value.Contains("'")) {
        throw "Shell value contains single quote and cannot be safely quoted: $Value"
    }
    return "'$Value'"
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function New-SyncShellScript {
    return @'
#!/bin/sh
set -eu
umask 077
BASE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONF="$BASE_DIR/router-cert-sync.conf"
if [ ! -r "$CONF" ]; then
    echo "missing config: $CONF" >&2
    exit 1
fi
. "$CONF"
LOG_PREFIX=${LOG_PREFIX:-router-cert-sync}
SSH_KEY=${SSH_KEY:-$BASE_DIR/.ssh/router_cert_sync}
KNOWN_HOSTS=${KNOWN_HOSTS:-$BASE_DIR/.ssh/known_hosts}
BACKUP_DIR=${BACKUP_DIR:-$BASE_DIR/backups}
CURRENT_DIR=${CURRENT_DIR:-$BASE_DIR/current}
ROUTER_PORT=${ROUTER_PORT:-22}
ROUTER_CHAIN_PATH=${ROUTER_CHAIN_PATH:-}
REMOTE="$ROUTER_USER@$ROUTER_HOST"
SSH_OPTS="-i $SSH_KEY -p $ROUTER_PORT -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=$KNOWN_HOSTS"
SCP_OPTS="-i $SSH_KEY -P $ROUTER_PORT -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=$KNOWN_HOSTS"
log() {
    printf '%s %s %s\n' "$(date '+%F %T')" "$LOG_PREFIX" "$*"
}
require_file() {
    if [ ! -s "$1" ]; then
        log "required file missing or empty: $1"
        exit 1
    fi
}
restart_service() {
    if [ -x "$1" ]; then
        "$1" restart >/dev/null 2>&1 || log "restart failed: $1"
    fi
}
remote_copy() {
    ssh $SSH_OPTS "$REMOTE" "cat '$1'" > "$2"
}
TMP_DIR=$(mktemp -d /tmp/router-cert-sync.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM
mkdir -p "$BACKUP_DIR" "$CURRENT_DIR" "$BASE_DIR/.ssh"
chmod 700 "$BASE_DIR/.ssh"
remote_copy "$ROUTER_CERT_PATH" "$TMP_DIR/router-cert.pem"
remote_copy "$ROUTER_KEY_PATH" "$TMP_DIR/router-key.pem"
require_file "$TMP_DIR/router-cert.pem"
require_file "$TMP_DIR/router-key.pem"
awk 'BEGIN{p=0} /-----BEGIN CERTIFICATE-----/{p=1} p{print} /-----END CERTIFICATE-----/{exit}' "$TMP_DIR/router-cert.pem" > "$TMP_DIR/leaf.pem"
awk 'BEGIN{n=0} /-----BEGIN CERTIFICATE-----/{n++} n>1{print}' "$TMP_DIR/router-cert.pem" > "$TMP_DIR/chain.pem"
if [ -n "$ROUTER_CHAIN_PATH" ]; then
    if remote_copy "$ROUTER_CHAIN_PATH" "$TMP_DIR/router-chain.pem" >/dev/null 2>&1 && [ -s "$TMP_DIR/router-chain.pem" ]; then
        cp "$TMP_DIR/router-chain.pem" "$TMP_DIR/chain.pem"
    fi
fi
require_file "$TMP_DIR/leaf.pem"
CERT_PUB=$(openssl x509 -in "$TMP_DIR/leaf.pem" -pubkey -noout)
KEY_PUB=$(openssl pkey -in "$TMP_DIR/router-key.pem" -pubout 2>/dev/null || openssl rsa -in "$TMP_DIR/router-key.pem" -pubout 2>/dev/null)
if [ "$CERT_PUB" != "$KEY_PUB" ]; then
    log "certificate and private key do not match"
    exit 1
fi
if [ -f /etc/stunnel/stunnel.pem ] && cmp -s "$TMP_DIR/leaf.pem" "$CURRENT_DIR/cert.pem" 2>/dev/null && cmp -s "$TMP_DIR/router-key.pem" "$CURRENT_DIR/privkey.pem" 2>/dev/null && cmp -s "$TMP_DIR/chain.pem" "$CURRENT_DIR/chain.pem" 2>/dev/null; then
    log "certificate unchanged"
    exit 0
fi
STAMP=$(date '+%Y%m%d-%H%M%S')
if [ -f /etc/stunnel/stunnel.pem ]; then
    cp /etc/stunnel/stunnel.pem "$BACKUP_DIR/stunnel.pem.$STAMP"
fi
if [ -f /etc/stunnel/uca.pem ]; then
    cp /etc/stunnel/uca.pem "$BACKUP_DIR/uca.pem.$STAMP"
fi
cat "$TMP_DIR/leaf.pem" "$TMP_DIR/router-key.pem" > /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem
if [ -s "$TMP_DIR/chain.pem" ]; then
    cp "$TMP_DIR/chain.pem" /etc/stunnel/uca.pem
    chmod 600 /etc/stunnel/uca.pem
fi
cp "$TMP_DIR/leaf.pem" "$CURRENT_DIR/cert.pem"
cp "$TMP_DIR/router-key.pem" "$CURRENT_DIR/privkey.pem"
cp "$TMP_DIR/chain.pem" "$CURRENT_DIR/chain.pem"
cat "$TMP_DIR/leaf.pem" "$TMP_DIR/chain.pem" > "$CURRENT_DIR/fullchain.pem"
chmod 600 "$CURRENT_DIR"/*.pem
restart_service /etc/init.d/Qthttpd.sh
restart_service /etc/init.d/thttpd.sh
restart_service /etc/init.d/stunnel.sh
if [ -x "$BASE_DIR/post-install.sh" ]; then
    "$BASE_DIR/post-install.sh" "$CURRENT_DIR/cert.pem" "$CURRENT_DIR/privkey.pem" "$CURRENT_DIR/fullchain.pem" || log "post-install hook failed"
fi
log "certificate installed"
'@
}

function New-ConfigContent {
    $values = [ordered]@{
        ROUTER_HOST = $RouterHost
        ROUTER_USER = $RouterUser
        ROUTER_PORT = [string]$RouterPort
        ROUTER_CERT_PATH = $RouterCertPath
        ROUTER_KEY_PATH = $RouterKeyPath
        ROUTER_CHAIN_PATH = $RouterChainPath
        SSH_KEY = "$NasInstallDir/.ssh/router_cert_sync"
        BACKUP_DIR = "$NasInstallDir/backups"
        LOG_PREFIX = "router-cert-sync"
    }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($item in $values.GetEnumerator()) {
        $lines.Add("$($item.Key)=$((ConvertTo-ShLiteral $item.Value))") | Out-Null
    }
    return ($lines -join "`n") + "`n"
}

function New-KeyPair([string]$PrivateKeyPath) {
    $publicKeyPath = "$PrivateKeyPath.pub"
    if ((Test-Path -LiteralPath $PrivateKeyPath) -and (Test-Path -LiteralPath $publicKeyPath) -and -not $Force) {
        Write-OK "Using existing key $PrivateKeyPath"
        return
    }
    if ((Test-Path -LiteralPath $PrivateKeyPath) -or (Test-Path -LiteralPath $publicKeyPath)) {
        Remove-Item -LiteralPath $PrivateKeyPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $publicKeyPath -Force -ErrorAction SilentlyContinue
    }
    $comment = "router-qnap-cert-sync@$env:COMPUTERNAME"
    Invoke-Native -FilePath "ssh-keygen" -Arguments @("-t", "ed25519", "-C", $comment, "-f", $PrivateKeyPath, "-N", '""') | Out-Null
    Write-OK "Generated $PrivateKeyPath"
}

function Install-RouterKey([string]$PublicKey) {
    Write-Step "Installing NAS sync public key on router $RouterUser@$RouterHost"
    $pub = ConvertTo-ShLiteral $PublicKey
    $command = "umask 077; mkdir -p /jffs/.ssh /root/.ssh; touch /jffs/.ssh/authorized_keys; nvram get sshd_authkeys >> /jffs/.ssh/authorized_keys 2>/dev/null || true; grep -qxF $pub /jffs/.ssh/authorized_keys 2>/dev/null || echo $pub >> /jffs/.ssh/authorized_keys; awk 'NF && !x[`$0]++' /jffs/.ssh/authorized_keys > /tmp/router-qnap-authkeys; cp /tmp/router-qnap-authkeys /jffs/.ssh/authorized_keys; cp /jffs/.ssh/authorized_keys /root/.ssh/authorized_keys 2>/dev/null || true; " + 'nvram set sshd_authkeys="$(cat /jffs/.ssh/authorized_keys)" >/dev/null 2>&1 || true; nvram commit >/dev/null 2>&1 || true; service restart_sshd >/dev/null 2>&1 || true'
    $exitCode = Invoke-Ssh -Target "$RouterUser@$RouterHost" -Port $RouterPort -Command $command -AllowFailure
    if ($exitCode -eq 0) {
        $script:RouterKeyInstalled = $true
        Write-OK "Router key installed"
        return
    }
    Write-WarnLine "Router SSH key install failed. Enable SSH on the router and paste this key in Administration > System > SSH Authentication key."
    Write-Host $PublicKey
}

function Install-NasFiles([string]$PrivateKeyPath) {
    Write-Step "Installing sync files on NAS $NasUser@$NasHost"
    $tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("router-qnap-cert-sync-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmpRoot | Out-Null
    try {
        $syncPath = Join-Path $tmpRoot "sync-router-cert.sh"
        $configPath = Join-Path $tmpRoot "router-cert-sync.conf"
        Write-Utf8NoBom -Path $syncPath -Content (New-SyncShellScript)
        Write-Utf8NoBom -Path $configPath -Content (New-ConfigContent)
        Copy-Scp -Source $syncPath -Target "$NasUser@$NasHost`:/tmp/sync-router-cert.sh" -Port $NasPort
        Copy-Scp -Source $configPath -Target "$NasUser@$NasHost`:/tmp/router-cert-sync.conf" -Port $NasPort
        Copy-Scp -Source $PrivateKeyPath -Target "$NasUser@$NasHost`:/tmp/router-cert-sync.key" -Port $NasPort
        $dir = ConvertTo-ShLiteral $NasInstallDir
        $command = "mkdir -p $dir $dir/.ssh $dir/backups $dir/current; mv /tmp/sync-router-cert.sh $dir/sync-router-cert.sh; mv /tmp/router-cert-sync.conf $dir/router-cert-sync.conf; mv /tmp/router-cert-sync.key $dir/.ssh/router_cert_sync; chmod 700 $dir/.ssh; chmod 755 $dir/sync-router-cert.sh; chmod 600 $dir/router-cert-sync.conf $dir/.ssh/router_cert_sync"
        Invoke-Ssh -Target "$NasUser@$NasHost" -Port $NasPort -Command $command | Out-Null
        Write-OK "Installed $NasInstallDir"
    }
    finally {
        Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-NasCron {
    Write-Step "Installing QNAP cron job"
    $line = "$CronSchedule $NasInstallDir/sync-router-cert.sh >> $NasInstallDir/sync.log 2>&1"
    $lineLiteral = ConvertTo-ShLiteral $line
    $marker = ConvertTo-ShLiteral "$NasInstallDir/sync-router-cert.sh"
    $command = "touch /etc/config/crontab; grep -vF $marker /etc/config/crontab > /tmp/router-cert-sync.crontab || true; echo $lineLiteral >> /tmp/router-cert-sync.crontab; cat /tmp/router-cert-sync.crontab > /etc/config/crontab; crontab /etc/config/crontab; /etc/init.d/crond.sh restart >/dev/null 2>&1 || /etc/init.d/crond.sh reload >/dev/null 2>&1 || true"
    Invoke-Ssh -Target "$NasUser@$NasHost" -Port $NasPort -Command $command | Out-Null
    Write-OK "Cron: $line"
}

function Invoke-InitialSync {
    if ($SkipInitialSync) {
        Write-WarnLine "Skipped initial sync"
        return
    }
    Write-Step "Running initial sync on NAS"
    $command = "$NasInstallDir/sync-router-cert.sh"
    $exitCode = Invoke-Ssh -Target "$NasUser@$NasHost" -Port $NasPort -Command $command -AllowFailure
    if ($exitCode -eq 0) {
        Write-OK "Initial sync completed"
    }
    else {
        Write-WarnLine "Initial sync failed. Check $NasInstallDir/sync.log or run: ssh $NasUser@$NasHost '$NasInstallDir/sync-router-cert.sh'"
    }
}

Assert-Command "ssh"
Assert-Command "scp"

$identityPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RouterIdentityPath)
if (-not (Test-Path -LiteralPath $identityPath)) {
    throw "Router identity key not found: $identityPath"
}
$publicKeyPath = "$identityPath.pub"
if (-not (Test-Path -LiteralPath $publicKeyPath)) {
    throw "Router public key not found: $publicKeyPath"
}
$publicKey = (Get-Content -LiteralPath $publicKeyPath -Raw).Trim()

Write-Step "Preparing NAS-to-router key"
Write-OK "Using $identityPath"
if ($InstallRouterAuthorizedKey) {
    Install-RouterKey -PublicKey $publicKey
}
else {
    Write-WarnLine "Router authorized keys not modified. The key in $publicKeyPath must already be authorized on the router."
}
Install-NasFiles -PrivateKeyPath $identityPath
Install-NasCron
Invoke-InitialSync

Write-Host ""
Write-Host "Router SSH setup if needed:" -ForegroundColor Cyan
Write-Host "  Asuswrt-Merlin UI > Administration > System > Enable SSH: LAN only, Password Login: yes for setup, Authorized Keys: paste the printed key."
Write-Host "  After this script succeeds, disable SSH password login and keep key auth enabled."
Write-Host ""
Write-Host "QNAP files:" -ForegroundColor Cyan
Write-Host "  $NasInstallDir/sync-router-cert.sh"
Write-Host "  $NasInstallDir/router-cert-sync.conf"
Write-Host "  $NasInstallDir/current/fullchain.pem"
Write-Host ""
Write-Host "If Merlin stores the cert elsewhere, rerun with -RouterCertPath, -RouterKeyPath, and optionally -RouterChainPath. Common Merlin paths are /jffs/.cert/cert.pem and /jffs/.cert/key.pem." -ForegroundColor Yellow
