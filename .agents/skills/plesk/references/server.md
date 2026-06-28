# Server Admin, Extensions, SSL, Security, Repair, Backup

## Server preferences

```bash
plesk bin server_pref --show
plesk bin server_pref --update -hostname NAME \
  -min_password_strength strong -ftp-over-ssl required
```

WAF server-level:
```bash
plesk bin server_pref --update-web-app-firewall \
  -waf-rule-engine on -waf-rule-set comodo_free
plesk bin server_pref --show-web-app-firewall
```

## Admin / API keys

```bash
plesk bin admin --info
plesk bin admin --get-login-link              # one-time login URL
plesk bin admin --set-admin-password          # (PSA_PASSWORD env)
plesk login                                  # shorthand login URL
plesk bin secret_key --create [-ip-address IP] [-description STRING]
plesk bin secret_key --list
plesk bin secret_key --delete -key KEY
```

## Customers / Resellers

```bash
plesk bin customer --create LOGIN -name "Full Name" -email E [-company C]
plesk bin customer --update LOGIN [flags]
plesk bin customer --remove LOGIN
plesk bin customer --list
plesk bin reseller --create LOGIN -name "Name" [-reseller-plan NAME]
```

## Extensions

```bash
plesk bin extension --list
plesk bin extension --install NAME       # from catalog
plesk bin extension --install-url URL    # from URL
plesk bin extension --uninstall NAME
plesk bin extension --exec NAME COMMAND [OPTS]
```

## WP Toolkit

```bash
plesk ext wp-toolkit --list
plesk ext wp-toolkit --info -instance-id ID
plesk ext wp-toolkit --install -domain-name DOMAIN [-path PATH] [-version VER] \
  [-admin-login L] [-admin-email E] [-admin-password P] [-title T]
plesk ext wp-toolkit --remove -instance-id ID
plesk ext wp-toolkit --clone -source-instance-id ID -target-domain-name DOMAIN
plesk ext wp-toolkit --wp-cli -instance-id ID -cmd "WP_CLI_COMMAND"
plesk ext wp-toolkit --plugins -instance-id ID -operation list|install|activate|update|remove
plesk ext wp-toolkit --themes -instance-id ID -operation list|activate|update|remove
plesk ext wp-toolkit --smart-update -instance-id ID
plesk ext wp-toolkit --versions
```

## SSL / Certificates

```bash
plesk bin certificate --create CERTNAME -domain DOMAIN \
  -key-file KEY -cert-file CERT [-cacert-file CA]
plesk bin certificate --remove CERTNAME -domain DOMAIN
plesk bin certificate --list -domain DOMAIN
plesk bin certificate --assign-cert CERTNAME -ip IP
# Let's Encrypt
plesk bin extension --exec letsencrypt cli.php -d DOMAIN --renew
```

HTTP/2 and HTTP/3:
```bash
plesk bin http2_pref --enable / --disable / --status
plesk bin http3_pref --enable / --disable / --status
```

## IP management

```bash
plesk bin ipmanage --ip_list                 # list IPs
plesk bin ipmanage --create IP
plesk bin ipmanage --reread                  # re-read from system
plesk bin ipmanage --auto-remap              # auto-remap IPs
```

## Fail2Ban

```bash
plesk bin ip_ban --enable / --disable
plesk bin ip_ban --info
plesk bin ip_ban --update -ban_period N -ban_time_window N -max_retries N
plesk bin ip_ban --banned                    # list banned IPs
plesk bin ip_ban --unban "IP,jail"
plesk bin ip_ban --add-trusted "IP"
plesk bin ip_ban --jails                     # list jails
plesk bin ip_ban --enable-jails "name;..."
```

## Apache modules

```bash
plesk bin apache --status
plesk bin apache --enable-module MODULE
plesk bin apache --disable-module MODULE
plesk bin apache --set-mpm prefork|event
```

## ModSecurity control

```bash
/opt/psa/admin/sbin/modsecurity_ctl --status
/opt/psa/admin/sbin/modsecurity_ctl --enable / --disable
/opt/psa/admin/sbin/modsecurity_ctl --list-rulesets [--enabled]
/opt/psa/admin/sbin/modsecurity_ctl --list-tags
/opt/psa/admin/sbin/modsecurity_ctl --install -R comodo_free [--with-backup]
/opt/psa/admin/sbin/modsecurity_ctl --rollback -R RULESET
```

## Repair

```bash
plesk repair fs [DOMAIN] -y         # filesystem permissions (most common)
plesk repair web [DOMAIN] -y        # web server config
plesk repair mail [DOMAIN] -y       # mail service
plesk repair dns -y                 # DNS zones
plesk repair db -y                  # database consistency
plesk repair mysql -y               # MySQL/MariaDB
plesk repair all                    # interactive full check
# Flags: -y (auto-fix), -n (check only), -v (verbose)
```

## Web server config rebuild

```bash
plesk sbin httpdmng --reconfigure-all              # all vhosts
plesk sbin httpdmng --reconfigure-domain DOMAIN    # single domain
plesk sbin httpdmng --reconfigure-server           # server config only
systemctl reload apache2 && systemctl reload nginx  # apply
```

## Backup / Restore

```bash
plesk bin pleskbackup server -output-file /path/backup.tar
plesk bin pleskbackup domains-name DOMAIN -output-file /path/backup.tar
plesk bin pleskrestore --restore /path/backup.tar -level server|domains
plesk bin scheduled-backup --list
```
