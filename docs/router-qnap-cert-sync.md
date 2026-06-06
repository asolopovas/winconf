# Router -> QNAP cert sync

Purpose: QNAP pulls the Asuswrt-Merlin Let's Encrypt cert from router and installs it as QTS SSL cert.

## SSH aliases

Must exist in `~/.ssh/config`:

```sshconfig
Host router
  HostName 192.168.1.1
  User asolopovas
  Port 33133

Host nas-admin
  HostName 192.168.1.100
  User admin
  Port 990
```

`ssh router` and `ssh nas-admin` must work before setup.

## Router

Merlin SSH: enabled on LAN.

Authorized key required on router:

```text
~/.ssh/id_rsa.pub
```

Do not overwrite router authorized keys during normal setup.

Cert paths used:

```text
/jffs/.le/agreen.ddns.net_ecc/fullchain.cer
/jffs/.le/agreen.ddns.net_ecc/domain.key
/jffs/.le/agreen.ddns.net_ecc/ca.cer
```

## Setup / restore after NAS reset

```powershell
cd ~/winconf
./scripts/inst-router-qnap-cert-sync.ps1
```

The script copies `~/.ssh/id_rsa` to the NAS sync dir so NAS can pull from router.

## Installed on QNAP

```text
/share/Public/router-cert-sync/sync-router-cert.sh
/share/Public/router-cert-sync/router-cert-sync.conf
/share/Public/router-cert-sync/.ssh/router_cert_sync
/share/Public/router-cert-sync/current/cert.pem
/share/Public/router-cert-sync/current/privkey.pem
/share/Public/router-cert-sync/current/fullchain.pem
/share/Public/router-cert-sync/current/chain.pem
```

QTS SSL targets:

```text
/etc/stunnel/stunnel.pem
/etc/stunnel/uca.pem
```

Cron:

```cron
17 4 * * * /share/Public/router-cert-sync/sync-router-cert.sh >> /share/Public/router-cert-sync/sync.log 2>&1
```

## Local HTTPS without browser warning

Do not use `https://192.168.1.100`; Let's Encrypt certs are for DNS names, not this LAN IP.

Use:

```text
https://agreen.ddns.net
```

LAN DNS override on router:

```text
/jffs/configs/dnsmasq.conf.add
address=/agreen.ddns.net/192.168.1.100
```

Setup:

```powershell
./scripts/inst-router-qnap-local-dns.ps1
```

Check:

```powershell
nslookup agreen.ddns.net 192.168.1.1
```

## Manual checks

```bash
ssh nas-admin '/share/Public/router-cert-sync/sync-router-cert.sh'
ssh nas-admin 'openssl x509 -in /share/Public/router-cert-sync/current/cert.pem -noout -subject -issuer -dates'
ssh nas-admin 'tail -20 /share/Public/router-cert-sync/sync.log'
```

## After router reset

1. Enable Merlin SSH on LAN.
2. Add `~/.ssh/id_rsa.pub` to router SSH authorized keys.
3. Confirm `ssh router` works.
4. Run `./scripts/inst-router-qnap-cert-sync.ps1`.
