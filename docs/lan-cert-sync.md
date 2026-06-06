# LAN cert sync

Scripts:

```text
scripts/home-net-setup.ps1
scripts/inst-lan-cert-sync.ps1
scripts/inst-lan-dns-override.ps1
scripts/inst-service-certs.ps1
```

## One-command setup

```powershell
./scripts/home-net-setup.ps1 `
  -SourceAlias router `
  -TargetAlias nas-admin `
  -Domain your.name.example `
  -TargetIp 192.168.1.100 `
  -RemoteCertPath /path/to/fullchain.pem `
  -RemoteKeyPath /path/to/privkey.pem `
  -RemoteChainPath /path/to/chain.pem
```

Runs cert sync, LAN DNS override, and Docker service HTTPS setup. In Git Bash, prefix with `MSYS_NO_PATHCONV=1` when passing `/jffs/...` paths.

Optional:

```powershell
-Update                  # docker compose pull + up -d
-FixJellyfinThumbnails   # queue Jellyfin image/library repair tasks
```

## Cert source -> target

Source and target must have SSH aliases:

```text
ssh router
ssh nas-admin
```

Setup target cert sync:

```powershell
./scripts/inst-lan-cert-sync.ps1 `
  -SourceAlias router `
  -TargetAlias nas-admin `
  -RemoteCertPath /path/to/fullchain.pem `
  -RemoteKeyPath /path/to/privkey.pem `
  -RemoteChainPath /path/to/chain.pem `
  -InstallSourceAuthorizedKey
```

Creates dedicated key:

```text
~/.ssh/id_cert_sync
~/.ssh/id_cert_sync.pub
```

Target install dir:

```text
/share/Public/cert-sync
```

Target cert files:

```text
/share/Public/cert-sync/current/cert.pem
/share/Public/cert-sync/current/privkey.pem
/share/Public/cert-sync/current/fullchain.pem
/share/Public/cert-sync/current/chain.pem
```

QTS SSL files updated:

```text
/etc/stunnel/stunnel.pem
/etc/stunnel/uca.pem
```

Cron:

```cron
17 4 * * * /share/Public/cert-sync/sync-cert.sh >> /share/Public/cert-sync/sync.log 2>&1
```

## LAN DNS override

Use DNS name, not IP, for valid HTTPS.

```powershell
./scripts/inst-lan-dns-override.ps1 `
  -DnsHostAlias router `
  -Domain your.name.example `
  -TargetIp 192.168.1.100
```

Check:

```powershell
nslookup your.name.example 192.168.1.1
```

## Docker services

Creates/updates Docker Compose for Jellyfin and qBittorrent with cert mounts.

```powershell
./scripts/inst-service-certs.ps1 `
  -NasAlias nas-admin `
  -Domain your.name.example `
  -SyncDir /share/Public/cert-sync `
  -Update `
  -FixJellyfinThumbnails
```

Writes qBittorrent WebUI credentials to:

```text
~/Desktop/qbittorrent-credentials.txt
```

URLs:

```text
https://your.name.example:8920  # Jellyfin
https://your.name.example:6363  # qBittorrent
```

Compose paths:

```text
/share/CACHEDEV1_DATA/Admin/container-station-data/application/jellyfin/docker-compose.yml
/share/CACHEDEV1_DATA/Admin/container-station-data/application/qbittorrent/docker-compose.yml
```

Service cert paths:

```text
/share/CACHEDEV1_DATA/Config/jellyfin/config/ssl/service-cert.pfx
/share/CACHEDEV1_DATA/Config/qbittorrent/certs/fullchain.pem
/share/CACHEDEV1_DATA/Config/qbittorrent/certs/privkey.pem
```

Renew hook:

```text
/share/Public/cert-sync/post-install.sh
```

## Checks

```bash
ssh nas-admin '/share/Public/cert-sync/sync-cert.sh'
ssh nas-admin '/share/Public/cert-sync/post-install.sh'
ssh nas-admin 'openssl x509 -in /share/Public/cert-sync/current/cert.pem -noout -subject -issuer -dates'
```
