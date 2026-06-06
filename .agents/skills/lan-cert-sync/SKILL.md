---
name: lan-cert-sync
description: Set up LAN certificate sync from an SSH-accessible certificate source to a QNAP/NAS target, including QTS SSL, local DNS override, and Jellyfin/qBittorrent Docker HTTPS using the same Let's Encrypt certificate.
---

# LAN Cert Sync

Use when configuring a NAS to reuse a Let's Encrypt certificate from another LAN device.

## Rules

- Use DNS names for HTTPS. IP URLs like `https://192.168.x.x` will fail name validation unless the cert has an IP SAN.
- Do not hardcode private domains, usernames, or cert paths in reusable scripts. Prompt or accept parameters.
- Use a dedicated sync key, e.g. `~/.ssh/id_cert_sync`; do not reuse a personal SSH key unless explicitly requested.
- On Git Bash/Windows, use `MSYS_NO_PATHCONV=1` when passing POSIX remote paths like `/jffs/...` to PowerShell/native commands.
- Some embedded SSH servers lack SFTP. Pull remote files with `ssh ... cat '/path'`, not `scp`, when needed.
- Never overwrite existing authorized keys wholesale. Append/dedupe only.

## QNAP/QTS cert install

QTS SSL files:

```text
/etc/stunnel/stunnel.pem  # leaf cert + private key
/etc/stunnel/uca.pem      # chain/intermediate
```

Restart after update:

```sh
/etc/init.d/Qthttpd.sh restart
/etc/init.d/thttpd.sh restart
/etc/init.d/stunnel.sh restart
```

Keep synced certs under a neutral dir:

```text
/share/Public/cert-sync/current/cert.pem
/share/Public/cert-sync/current/privkey.pem
/share/Public/cert-sync/current/fullchain.pem
/share/Public/cert-sync/current/chain.pem
```

Cron example:

```cron
17 4 * * * /share/Public/cert-sync/sync-cert.sh >> /share/Public/cert-sync/sync.log 2>&1
```

## LAN DNS override

For browser-valid local HTTPS, map the certificate DNS name to the NAS LAN IP on the LAN DNS server.

Asuswrt-Merlin dnsmasq file:

```text
/jffs/configs/dnsmasq.conf.add
```

Entry:

```text
address=/CERT_DNS_NAME/NAS_LAN_IP
```

Restart:

```sh
service restart_dnsmasq
```

## Jellyfin Docker HTTPS

Jellyfin expects PKCS#12/PFX:

```sh
openssl pkcs12 -export \
  -out /path/to/jellyfin/config/ssl/service-cert.pfx \
  -inkey privkey.pem \
  -in cert.pem \
  -certfile chain.pem \
  -passout pass:
```

Jellyfin `network.xml` values:

```xml
<EnableHttps>true</EnableHttps>
<RequireHttps>false</RequireHttps>
<CertificatePath>/config/ssl/service-cert.pfx</CertificatePath>
<InternalHttpsPort>8920</InternalHttpsPort>
<PublicHttpsPort>8920</PublicHttpsPort>
```

Compose must publish HTTPS:

```yaml
ports:
  - "8096:8096"
  - "8920:8920"
volumes:
  - /share/.../Config/jellyfin/config:/config
  - /share/.../Config/jellyfin/cache:/cache
```

Avoid nested config mounts such as `.../config/config:/config`; Jellyfin marker files can cause startup failure.

## qBittorrent Docker HTTPS

Use LinuxServer qBittorrent or another container that can read mounted PEM files.

Mount readable cert copies, not root-only sync files:

```yaml
volumes:
  - /share/.../Config/qbittorrent:/config
  - /share/.../Config/qbittorrent/certs:/certs:ro
```

Config keys:

```ini
[Preferences]
WebUI\HTTPS\Enabled=true
WebUI\HTTPS\CertificatePath=/certs/fullchain.pem
WebUI\HTTPS\KeyPath=/certs/privkey.pem
WebUI\Port=6363
```

Set cert file ownership/permissions for container user:

```sh
chown PUID:PGID fullchain.pem privkey.pem
chmod 640 fullchain.pem privkey.pem
```

If replacing a QNAP QPKG qBittorrent with Docker, stop and disable QPKG to avoid port/service conflicts:

```sh
/sbin/qpkg_cli --stop qBittorrent2
/sbin/qpkg_cli --disable qBittorrent2
```

## Renewal hook

Run service cert updates after each base cert sync:

```text
/share/Public/cert-sync/post-install.sh
```

This hook should update Jellyfin PFX, copy qBittorrent PEMs, and restart/recreate containers with `docker compose up -d`.

For container updates while preserving config volumes:

```sh
docker compose pull
docker compose up -d
```

For Jellyfin missing thumbnails/posters: create/use an API key, call `/Library/Refresh`, run scheduled tasks `RefreshLibrary`, `RefreshChapterImages`, `RefreshTrickplayImages`, and refresh item IDs seen in logs like `URL GET /Items/<id>/Images/Primary` with:

```text
POST /Items/<id>/Refresh?Recursive=true&ImageRefreshMode=FullRefresh&MetadataRefreshMode=FullRefresh&ReplaceAllImages=true
```

## Verification

```sh
/share/Public/cert-sync/sync-cert.sh
/share/Public/cert-sync/post-install.sh
openssl x509 -in /share/Public/cert-sync/current/cert.pem -noout -subject -issuer -dates
```

Remote TLS checks:

```sh
openssl s_client -connect NAS_IP:8920 -servername CERT_DNS_NAME </dev/null | openssl x509 -noout -subject -dates -fingerprint -sha256
openssl s_client -connect NAS_IP:6363 -servername CERT_DNS_NAME </dev/null | openssl x509 -noout -subject -dates -fingerprint -sha256
```

HTTP checks by DNS name:

```sh
curl --resolve CERT_DNS_NAME:8920:NAS_IP -I https://CERT_DNS_NAME:8920
curl --resolve CERT_DNS_NAME:6363:NAS_IP -I https://CERT_DNS_NAME:6363
```
