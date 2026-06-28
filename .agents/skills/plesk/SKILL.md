---
name: plesk
description: "Manage Plesk Obsidian servers: domains, hosting, WAF/ModSecurity, permissions, SSL, DNS, databases, mail, WP Toolkit, and CLI administration. Covers diagnostics, security hardening, and multi-app hosting (WordPress, Laravel, Nuxt)."
category: devops
risk: medium
source: operational-experience
created: "2026-06-09"
---

# Plesk Obsidian CLI Administration

Operate Plesk hosting servers from the shell. This file is the map.
Open the reference that matches your task:

| Category | Reference |
|----------|-----------|
| Domains, subscriptions, service plans, PHP, web server | [references/hosting.md](references/hosting.md) |
| DNS records, mail, spam, greylisting | [references/dns-mail.md](references/dns-mail.md) |
| Server admin, extensions, SSL, IP, Fail2Ban, repair, backup | [references/server.md](references/server.md) |
| WAF / ModSecurity per-domain configuration | [references/waf.md](references/waf.md) |
| Diagnose 403/500 errors, permissions, broken sites | [references/diagnostics.md](references/diagnostics.md) |

## Architecture

- nginx reverse proxy -> Apache -> PHP-FPM (per-domain sockets).
- Config hierarchy: server -> service plan -> subscription -> domain.
- Auto-generated vhosts: `/etc/apache2/plesk.conf.d/vhosts/DOMAIN.conf` -- NEVER edit.
- Custom overrides: `/var/www/vhosts/system/DOMAIN/conf/vhost.conf` (Apache),
  `vhost_nginx.conf` (nginx).
- Rebuild after changes: `plesk sbin httpdmng --reconfigure-all`

## Key directories

```
/var/www/vhosts/DOMAIN/                  subscription root
  public_html/ | httpdocs/               document root (varies)
/var/www/vhosts/system/DOMAIN/
  conf/                                  custom vhost overrides
  logs/                                  per-domain logs (see below)
  php-fpm.sock                           PHP-FPM socket
/etc/apache2/plesk.conf.d/
  server.conf                            server-level (ModSecurity default)
  vhosts/DOMAIN.conf                     per-domain (auto-generated)
/etc/apache2/modsecurity.d/
  rules/comodo_free/                     WAF rules
  zz_rules.conf                          active rule includes
/opt/psa/bin/                            CLI utilities
/opt/psa/admin/sbin/                     internal admin tools (modsecurity_ctl, httpdmng)
/opt/psa/var/certificates/               SSL certs
```

## Log locations

Per-domain (replace DOMAIN):
```
/var/www/vhosts/system/DOMAIN/logs/error_log              Apache errors (PHP fatals, .htaccess, permission denied)
/var/www/vhosts/system/DOMAIN/logs/proxy_error_log        nginx proxy errors (502, upstream timeouts, permission denied)
/var/www/vhosts/system/DOMAIN/logs/access_log             Apache access (HTTP)
/var/www/vhosts/system/DOMAIN/logs/access_ssl_log         Apache access (HTTPS)
/var/www/vhosts/system/DOMAIN/logs/proxy_access_log       nginx proxy access (HTTP)
/var/www/vhosts/system/DOMAIN/logs/proxy_access_ssl_log   nginx proxy access (HTTPS)
```

Server-wide:
```
/var/log/apache2/error.log             Apache global errors
/var/log/nginx/error.log               nginx global errors
/var/log/modsec_audit.log              ModSecurity audit log (WAF blocks)
/var/log/plesk/panel.log               Plesk panel log
/var/log/plesk/php-fpm/DOMAIN.log      PHP-FPM per-domain log (if configured)
/var/log/mail.log                      Mail delivery log
/var/log/fail2ban.log                  Fail2Ban bans/unbans
```

## Permission model

- System user per subscription, group `psacln`.
- Vhost dir: `USER:psaserv 0710`. Document root: `USER:psaserv 0750`.
- Apache runs as `www-data` in group `psaserv` (NOT `psacln`).
- If doc root group = `psacln` -> 403 on everything. Fix: `plesk repair fs DOMAIN -y`.

## Database access

`plesk db -e "SQL"` or `plesk db -Ne "SQL"` (no headers).

Key tables: `domains` (id, name), `hosting` (dom_id, www_root, ssl),
`dom_param` (per-domain key-value), `WebServerSettingsParameters` (WAF/web settings),
`sys_users`, `Subscriptions`.

```sql
-- Get domain's web server settings ID
SELECT dp.val FROM dom_param dp, domains d
WHERE dp.dom_id = d.id AND d.name = 'DOMAIN' AND dp.param = 'webServerSettingsId'
```

## Environment variables

```
PSA_PASSWORD=PASS              plaintext password (avoids CLI exposure)
FTP_PASSWORD=PASS              for backup-storage --configure
PLESK_BACKUP_PASSWORD=PASS     backup encryption password
```

## Keep this skill current

When a session surfaces a durable nuance -- update the right reference file.
Edit in place. Prune stale content. Keep concise, ASCII-only.
