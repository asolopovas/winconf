[CmdletBinding()]
param(
    [string]$NasAlias = "nas-admin",
    [string]$Domain = "",
    [string]$SyncDir = "/share/Public/cert-sync",
    [string]$AppRoot = "/share/CACHEDEV1_DATA/Admin/container-station-data/application",
    [string]$ConfigRoot = "/share/CACHEDEV1_DATA/Config",
    [string]$MediaRoot = "/share/CACHEDEV1_DATA",
    [int]$Puid = 1000,
    [int]$Pgid = 100,
    [int]$JellyfinHttpPort = 8096,
    [int]$JellyfinHttpsPort = 8920,
    [int]$QbittorrentWebPort = 6363,
    [int]$QbittorrentTorrentPort = 4609,
    [string]$CredentialsOutputPath = "$env:USERPROFILE\Desktop\qbittorrent-credentials.txt",
    [switch]$Update,
    [switch]$FixJellyfinThumbnails,
    [switch]$SkipComposeUp,
    [switch]$KeepQpkgQbittorrent
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function ConvertTo-ShLiteral([string]$Value) {
    if ($Value.Contains("'")) { throw "Shell value contains single quote and cannot be safely quoted: $Value" }
    return "'$Value'"
}

function Read-RequiredSetting([string]$Name, [string]$Value, [string]$Prompt) {
    if (-not [string]::IsNullOrWhiteSpace($Value)) { return $Value }
    $answer = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($answer)) { throw "$Name is required" }
    return $answer.Trim()
}

$Domain = Read-RequiredSetting -Name "Domain" -Value $Domain -Prompt "Certificate DNS name, e.g. nas.example.com"

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) { throw "ssh was not found in PATH" }
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) { throw "scp was not found in PATH" }

function Save-QbittorrentCredentials {
    param(
        [string]$NasAlias,
        [string]$Domain,
        [int]$Port,
        [string]$Path
    )
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $logText = (& ssh $NasAlias 'export PATH=/share/CACHEDEV1_DATA/.qpkg/container-station/bin:$PATH; docker logs --tail 300 qbittorrent 2>&1' 2>&1 | Out-String)
    $userMatches = [regex]::Matches($logText, 'administrator username is:\s*(\S+)')
    $passMatches = [regex]::Matches($logText, 'temporary password[^:]*:\s*(\S+)')
    $username = if ($userMatches.Count -gt 0) { $userMatches[$userMatches.Count - 1].Groups[1].Value } else { 'admin' }
    $password = if ($passMatches.Count -gt 0) { $passMatches[$passMatches.Count - 1].Groups[1].Value } else { '' }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("qBittorrent WebUI") | Out-Null
    $lines.Add("URL: https://$Domain`:$Port") | Out-Null
    $lines.Add("Username: $username") | Out-Null
    if ($password) {
        $lines.Add("Password: $password") | Out-Null
    }
    else {
        $lines.Add("Password: not found in container logs; check: ssh $NasAlias 'docker logs qbittorrent 2>&1 | grep password'") | Out-Null
    }
    $lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
    Write-Utf8NoBom -Path $Path -Content (($lines -join "`r`n") + "`r`n")
    Write-Host "[OK] wrote $Path"
}

$skipComposeValue = if ($SkipComposeUp) { "1" } else { "0" }
$keepQpkgValue = if ($KeepQpkgQbittorrent) { "1" } else { "0" }
$updateValue = if ($Update) { "1" } else { "0" }
$fixThumbsValue = if ($FixJellyfinThumbnails) { "1" } else { "0" }

$installer = @'
#!/bin/sh
set -eu
DOMAIN=${DOMAIN:?missing DOMAIN}
SYNC_DIR=${SYNC_DIR:-/share/Public/cert-sync}
APP_ROOT=${APP_ROOT:-/share/CACHEDEV1_DATA/Admin/container-station-data/application}
CONFIG_ROOT=${CONFIG_ROOT:-/share/CACHEDEV1_DATA/Config}
MEDIA_ROOT=${MEDIA_ROOT:-/share/CACHEDEV1_DATA}
PUID=${PUID:-1000}
PGID=${PGID:-100}
JELLYFIN_HTTP_PORT=${JELLYFIN_HTTP_PORT:-8096}
JELLYFIN_HTTPS_PORT=${JELLYFIN_HTTPS_PORT:-8920}
QBIT_WEB_PORT=${QBIT_WEB_PORT:-6363}
QBIT_TORRENT_PORT=${QBIT_TORRENT_PORT:-4609}
SKIP_COMPOSE_UP=${SKIP_COMPOSE_UP:-0}
KEEP_QPKG_QBIT=${KEEP_QPKG_QBIT:-0}
UPDATE_CONTAINERS=${UPDATE_CONTAINERS:-0}
FIX_JELLYFIN_THUMBNAILS=${FIX_JELLYFIN_THUMBNAILS:-0}
PATH=/share/CACHEDEV1_DATA/.qpkg/container-station/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
CERT=$SYNC_DIR/current/cert.pem
KEY=$SYNC_DIR/current/privkey.pem
FULLCHAIN=$SYNC_DIR/current/fullchain.pem
CHAIN=$SYNC_DIR/current/chain.pem
SERVICES_DIR=$SYNC_DIR/services
JELLYFIN_APP=$APP_ROOT/jellyfin
QBIT_APP=$APP_ROOT/qbittorrent
JELLYFIN_CONFIG=$CONFIG_ROOT/jellyfin/config
JELLYFIN_CACHE=$CONFIG_ROOT/jellyfin/cache
QBIT_CONFIG=$CONFIG_ROOT/qbittorrent
log() { printf '%s service-certs %s\n' "$(date '+%F %T')" "$*"; }
backup() { [ -f "$1" ] && cp "$1" "$1.bak.$(date '+%Y%m%d-%H%M%S')"; }
set_xml_tag() {
    file=$1
    tag=$2
    value=$3
    tmp=/tmp/xmltag.$$
    if grep -q "<$tag>" "$file"; then
        sed "s#<$tag>.*</$tag>#<$tag>$value</$tag>#" "$file" > "$tmp"
        cat "$tmp" > "$file"
        rm -f "$tmp"
    fi
}
write_jellyfin_network() {
    mkdir -p "$JELLYFIN_CONFIG/config"
    cat > "$JELLYFIN_CONFIG/config/network.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BaseUrl />
  <EnableHttps>true</EnableHttps>
  <RequireHttps>false</RequireHttps>
  <CertificatePath>/config/ssl/service-cert.pfx</CertificatePath>
  <InternalHttpPort>$JELLYFIN_HTTP_PORT</InternalHttpPort>
  <InternalHttpsPort>$JELLYFIN_HTTPS_PORT</InternalHttpsPort>
  <PublicHttpPort>$JELLYFIN_HTTP_PORT</PublicHttpPort>
  <PublicHttpsPort>$JELLYFIN_HTTPS_PORT</PublicHttpsPort>
  <AutoDiscovery>true</AutoDiscovery>
  <EnableUPnP>false</EnableUPnP>
  <EnableIPv4>true</EnableIPv4>
  <EnableIPv6>false</EnableIPv6>
  <EnableRemoteAccess>true</EnableRemoteAccess>
  <LocalNetworkSubnets />
  <LocalNetworkAddresses />
  <KnownProxies />
  <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>
  <VirtualInterfaceNames><string>veth</string></VirtualInterfaceNames>
  <EnablePublishedServerUriByRequest>false</EnablePublishedServerUriByRequest>
  <PublishedServerUriBySubnet />
  <RemoteIPFilter />
  <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
</NetworkConfiguration>
EOF
}
write_jellyfin_compose() {
    mkdir -p "$JELLYFIN_APP" "$JELLYFIN_CONFIG" "$JELLYFIN_CACHE" "$MEDIA_ROOT/Music" "$MEDIA_ROOT/Video/Movies" "$MEDIA_ROOT/Video/Shows"
    cat > "$JELLYFIN_APP/docker-compose.yml" <<EOF
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "$JELLYFIN_HTTP_PORT:$JELLYFIN_HTTP_PORT"
      - "$JELLYFIN_HTTPS_PORT:$JELLYFIN_HTTPS_PORT"
    environment:
      TZ: GMT0IST-1
    volumes:
      - $JELLYFIN_CONFIG:/config
      - $JELLYFIN_CACHE:/cache
      - $MEDIA_ROOT/Music:/media/music
      - $MEDIA_ROOT/Video/Movies:/media/movies
      - $MEDIA_ROOT/Video/Shows:/media/shows
    devices:
      - /dev/dri:/dev/dri
EOF
}
write_qbit_conf() {
    mkdir -p "$QBIT_CONFIG/qBittorrent" "$QBIT_CONFIG/downloads" "$QBIT_CONFIG/watch"
    cat > "$QBIT_CONFIG/qBittorrent/qBittorrent.conf" <<EOF
[BitTorrent]
Session\\DefaultSavePath=/downloads
Session\\Port=$QBIT_TORRENT_PORT
Session\\QueueingSystemEnabled=true
Session\\TempPath=/downloads/tmp
Session\\TempPathEnabled=true

[LegalNotice]
Accepted=true

[Preferences]
General\\Locale=en
HostHeaderValidation=false
WebUI\\Address=*
WebUI\\AuthSubnetWhitelist=192.168.1.0/24
WebUI\\AuthSubnetWhitelistEnabled=false
WebUI\\HTTPS\\CertificatePath=/certs/fullchain.pem
WebUI\\HTTPS\\Enabled=true
WebUI\\HTTPS\\KeyPath=/certs/privkey.pem
WebUI\\Port=$QBIT_WEB_PORT
EOF
}
write_qbit_compose() {
    mkdir -p "$QBIT_APP"
    cat > "$QBIT_APP/docker-compose.yml" <<EOF
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    environment:
      PUID: "$PUID"
      PGID: "$PGID"
      TZ: GMT0IST-1
      WEBUI_PORT: "$QBIT_WEB_PORT"
      TORRENTING_PORT: "$QBIT_TORRENT_PORT"
    ports:
      - "$QBIT_WEB_PORT:$QBIT_WEB_PORT"
      - "$QBIT_TORRENT_PORT:$QBIT_TORRENT_PORT"
      - "$QBIT_TORRENT_PORT:$QBIT_TORRENT_PORT/udp"
    volumes:
      - $QBIT_CONFIG:/config
      - $MEDIA_ROOT/Video:/downloads
      - $QBIT_CONFIG/certs:/certs:ro
EOF
}
configure_jellyfin_cert() {
    mkdir -p "$JELLYFIN_CONFIG/ssl" "$SERVICES_DIR/jellyfin"
    openssl pkcs12 -export -out "$JELLYFIN_CONFIG/ssl/service-cert.pfx" -inkey "$KEY" -in "$CERT" -certfile "$CHAIN" -passout pass:
    cp "$JELLYFIN_CONFIG/ssl/service-cert.pfx" "$SERVICES_DIR/jellyfin/service-cert.pfx"
    chmod 600 "$JELLYFIN_CONFIG/ssl/service-cert.pfx" "$SERVICES_DIR/jellyfin/service-cert.pfx"
    if [ -f "$JELLYFIN_CONFIG/config/network.xml" ]; then
        backup "$JELLYFIN_CONFIG/config/network.xml"
        set_xml_tag "$JELLYFIN_CONFIG/config/network.xml" EnableHttps true
        set_xml_tag "$JELLYFIN_CONFIG/config/network.xml" RequireHttps false
        set_xml_tag "$JELLYFIN_CONFIG/config/network.xml" CertificatePath /config/ssl/service-cert.pfx
        set_xml_tag "$JELLYFIN_CONFIG/config/network.xml" InternalHttpsPort "$JELLYFIN_HTTPS_PORT"
        set_xml_tag "$JELLYFIN_CONFIG/config/network.xml" PublicHttpsPort "$JELLYFIN_HTTPS_PORT"
    else
        write_jellyfin_network
    fi
}
configure_qbit_cert() {
    mkdir -p "$QBIT_CONFIG/certs"
    cp "$FULLCHAIN" "$QBIT_CONFIG/certs/fullchain.pem"
    cp "$KEY" "$QBIT_CONFIG/certs/privkey.pem"
    chown "$PUID:$PGID" "$QBIT_CONFIG/certs/fullchain.pem" "$QBIT_CONFIG/certs/privkey.pem" 2>/dev/null || true
    chmod 640 "$QBIT_CONFIG/certs/fullchain.pem" "$QBIT_CONFIG/certs/privkey.pem"
    [ -f "$QBIT_CONFIG/qBittorrent/qBittorrent.conf" ] || write_qbit_conf
    backup "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    if grep -q '^WebUI\\HTTPS\\Enabled=' "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"; then
        sed -i 's#^WebUI\\HTTPS\\Enabled=.*#WebUI\\HTTPS\\Enabled=true#' "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    else
        printf '%s\n' 'WebUI\HTTPS\Enabled=true' >> "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    fi
    if grep -q '^WebUI\\HTTPS\\CertificatePath=' "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"; then
        sed -i 's#^WebUI\\HTTPS\\CertificatePath=.*#WebUI\\HTTPS\\CertificatePath=/certs/fullchain.pem#' "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    else
        printf '%s\n' 'WebUI\HTTPS\CertificatePath=/certs/fullchain.pem' >> "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    fi
    if grep -q '^WebUI\\HTTPS\\KeyPath=' "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"; then
        sed -i 's#^WebUI\\HTTPS\\KeyPath=.*#WebUI\\HTTPS\\KeyPath=/certs/privkey.pem#' "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    else
        printf '%s\n' 'WebUI\HTTPS\KeyPath=/certs/privkey.pem' >> "$QBIT_CONFIG/qBittorrent/qBittorrent.conf"
    fi
}
compose_up() {
    dir=$1
    name=$2
    if [ "$SKIP_COMPOSE_UP" = 1 ]; then
        log "skip compose up: $name"
        return
    fi
    if command -v docker >/dev/null 2>&1; then
        if [ "$UPDATE_CONTAINERS" = 1 ]; then
            (cd "$dir" && docker compose pull)
        fi
        (cd "$dir" && docker compose up -d)
    else
        log "docker not found"
    fi
}
fix_jellyfin_thumbnails() {
    [ "$FIX_JELLYFIN_THUMBNAILS" = 1 ] || return 0
    command -v curl >/dev/null 2>&1 || { log "curl not found; skip Jellyfin thumbnail fix"; return 0; }
    token_file="$SYNC_DIR/jellyfin-api-token"
    if [ ! -s "$token_file" ]; then
        sqlite=$(command -v sqlite3 || true)
        [ -n "$sqlite" ] || sqlite=/share/CACHEDEV1_DATA/.qpkg/Entware/bin/sqlite3
        [ -x "$sqlite" ] || { log "sqlite3 not found; skip Jellyfin thumbnail fix"; return 0; }
        token=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
        "$sqlite" "$JELLYFIN_CONFIG/data/jellyfin.db" "insert or ignore into ApiKeys(DateCreated,DateLastActivity,Name,AccessToken) values(datetime('now'),datetime('now'),'home-net-setup','$token');"
        printf '%s\n' "$token" > "$token_file"
        chmod 600 "$token_file"
        docker restart jellyfin >/dev/null 2>&1 || true
        sleep 30
    fi
    token=$(cat "$token_file")
    base="https://127.0.0.1:$JELLYFIN_HTTPS_PORT"
    curl -ks -X POST -H "X-Emby-Token: $token" "$base/Library/Refresh" >/dev/null 2>&1 || true
    for key in RefreshLibrary RefreshChapterImages RefreshTrickplayImages; do
        id=$(curl -ks -H "X-Emby-Token: $token" "$base/ScheduledTasks" | tr '{' '\n' | awk -F'"' -v k="$key" 'index($0,"\"Key\":\"" k "\""){for(i=1;i<=NF;i++) if($i=="Id"){print $(i+2); exit}}')
        [ -n "$id" ] && curl -ks -X POST -H "X-Emby-Token: $token" "$base/ScheduledTasks/Running/$id" >/dev/null 2>&1 || true
    done
    docker logs --tail 1200 jellyfin 2>&1 | sed -n 's#.*URL GET /Items/\([0-9a-f-]*\)/Images/Primary.*#\1#p' | sort -u | while read -r item; do
        [ -n "$item" ] && curl -ks -X POST -H "X-Emby-Token: $token" "$base/Items/$item/Refresh?Recursive=true&ImageRefreshMode=FullRefresh&MetadataRefreshMode=FullRefresh&ReplaceAllImages=true" >/dev/null 2>&1 || true
    done
    log "Jellyfin thumbnail repair queued"
}
[ -s "$CERT" ] || "$SYNC_DIR/sync-cert.sh"
[ -s "$CERT" ] || { log "missing cert: $CERT"; exit 1; }
[ -s "$KEY" ] || { log "missing key: $KEY"; exit 1; }
[ -s "$FULLCHAIN" ] || { log "missing fullchain: $FULLCHAIN"; exit 1; }
write_jellyfin_compose
configure_jellyfin_cert
write_qbit_compose
configure_qbit_cert
if [ "$KEEP_QPKG_QBIT" != 1 ]; then
    [ -x /etc/init.d/qBittorrent2.sh ] && /etc/init.d/qBittorrent2.sh stop >/dev/null 2>&1 || true
    [ -x /sbin/qpkg_cli ] && /sbin/qpkg_cli --stop qBittorrent2 >/dev/null 2>&1 || true
    [ -x /sbin/qpkg_cli ] && /sbin/qpkg_cli --disable qBittorrent2 >/dev/null 2>&1 || true
fi
compose_up "$JELLYFIN_APP" jellyfin
compose_up "$QBIT_APP" qbittorrent
fix_jellyfin_thumbnails
cat > "$SYNC_DIR/post-install.sh" <<EOF
#!/bin/sh
set -eu
DOMAIN='$DOMAIN' SYNC_DIR='$SYNC_DIR' APP_ROOT='$APP_ROOT' CONFIG_ROOT='$CONFIG_ROOT' MEDIA_ROOT='$MEDIA_ROOT' PUID='$PUID' PGID='$PGID' JELLYFIN_HTTP_PORT='$JELLYFIN_HTTP_PORT' JELLYFIN_HTTPS_PORT='$JELLYFIN_HTTPS_PORT' QBIT_WEB_PORT='$QBIT_WEB_PORT' QBIT_TORRENT_PORT='$QBIT_TORRENT_PORT' SKIP_COMPOSE_UP=0 KEEP_QPKG_QBIT='$KEEP_QPKG_QBIT' UPDATE_CONTAINERS=0 FIX_JELLYFIN_THUMBNAILS=0 "$SYNC_DIR/install-service-certs.sh"
EOF
chmod 755 "$SYNC_DIR/post-install.sh"
log "configured jellyfin: https://$DOMAIN:$JELLYFIN_HTTPS_PORT"
log "configured qbittorrent: https://$DOMAIN:$QBIT_WEB_PORT"
'@

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("service-certs-" + [guid]::NewGuid().ToString("N") + ".sh")
Write-Utf8NoBom -Path $tmp -Content $installer
try {
    & scp $tmp "$NasAlias`:/tmp/install-service-certs.sh"
    if ($LASTEXITCODE -ne 0) { throw "scp failed with exit code $LASTEXITCODE" }
    $remote = "mkdir -p '$SyncDir'; mv /tmp/install-service-certs.sh '$SyncDir/install-service-certs.sh'; chmod 755 '$SyncDir/install-service-certs.sh'; DOMAIN=$(ConvertTo-ShLiteral $Domain) SYNC_DIR=$(ConvertTo-ShLiteral $SyncDir) APP_ROOT=$(ConvertTo-ShLiteral $AppRoot) CONFIG_ROOT=$(ConvertTo-ShLiteral $ConfigRoot) MEDIA_ROOT=$(ConvertTo-ShLiteral $MediaRoot) PUID='$Puid' PGID='$Pgid' JELLYFIN_HTTP_PORT='$JellyfinHttpPort' JELLYFIN_HTTPS_PORT='$JellyfinHttpsPort' QBIT_WEB_PORT='$QbittorrentWebPort' QBIT_TORRENT_PORT='$QbittorrentTorrentPort' SKIP_COMPOSE_UP='$skipComposeValue' KEEP_QPKG_QBIT='$keepQpkgValue' UPDATE_CONTAINERS='$updateValue' FIX_JELLYFIN_THUMBNAILS='$fixThumbsValue' '$SyncDir/install-service-certs.sh'"
    & ssh $NasAlias $remote
    if ($LASTEXITCODE -ne 0) { throw "ssh failed with exit code $LASTEXITCODE" }
    if (-not $SkipComposeUp) {
        Start-Sleep -Seconds 8
        Save-QbittorrentCredentials -NasAlias $NasAlias -Domain $Domain -Port $QbittorrentWebPort -Path $CredentialsOutputPath
    }
}
finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
