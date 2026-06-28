# Plesk Diagnostics

Triage broken sites, HTTP errors, and permission issues.

## Quick triage

```bash
curl -sk -o /dev/null -w "%{http_code}" "https://DOMAIN/"
tail -30 /var/www/vhosts/system/DOMAIN/logs/error_log
tail -30 /var/www/vhosts/system/DOMAIN/logs/proxy_error_log
plesk bin domain --info DOMAIN | head -20
stat -c "%a %U:%G %n" /var/www/vhosts/DOMAIN/public_html
```

## 403 Forbidden

**Wrong group on document root (most common):**
```
AH00529: .htaccess pcfg_openfile: unable to check htaccess file, ensure it is readable
openat() "index.php" failed (13: Permission denied)
```
Root cause: doc root group is `psacln` instead of `psaserv`. Apache (`www-data`) is in
`psaserv` only.
```bash
plesk repair fs DOMAIN -y
stat -c "%a %U:%G %n" /var/www/vhosts/DOMAIN/public_html  # verify: psaserv
```

**WAF blocking:** No permission error in logs. Check `grep DOMAIN /var/log/modsec_audit.log | tail -20`.
Confirm by setting WAF to DetectionOnly temporarily.

**.htaccess rules:** Check for `Deny from all` or IP restrictions in `.htaccess`.

## 500 Internal Server Error

```bash
tail -30 /var/www/vhosts/system/DOMAIN/logs/error_log
plesk bin domain --info DOMAIN | grep -i php
systemctl status "plesk-php*-fpm" | head -20
```

## 502 Bad Gateway

nginx cannot reach Apache/PHP-FPM.
```bash
systemctl status apache2
ls -la /var/www/vhosts/system/DOMAIN/php-fpm.sock
systemctl restart "plesk-php*-fpm"
```

## Expected ownership (verify after `plesk repair fs`)

- `/var/www/vhosts/DOMAIN/` -> `USER:psaserv 0710`
- `/var/www/vhosts/DOMAIN/public_html` -> `USER:psaserv 0750`
- `wp-config.php` -> `USER:psacln 0600`

## Batch health check

```bash
for d in $(plesk bin domain --list); do
  code=$(curl -sk -o /dev/null -w "%{http_code}" "https://$d/" 2>/dev/null)
  [ "$code" != "200" ] && [ "$code" != "301" ] && [ "$code" != "302" ] && echo "$code $d"
done
```
