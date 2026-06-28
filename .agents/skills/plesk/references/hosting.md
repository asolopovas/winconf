# Hosting: Domains, Subscriptions, Service Plans, PHP

## domain / site / subscription

`domain` manages subscriptions. `site` manages domains within subscriptions.
`subscription` is an alias for subscription-level ops. They share most flags.

```bash
plesk bin domain --list                     # list all
plesk bin domain --info DOMAIN              # details
plesk bin domain --create DOMAIN -owner admin -ip IP -login USER \
  -php true -php_handler_id plesk-php83-fpm -ssl true -ssl-redirect true
plesk bin domain --update DOMAIN [flags]    # modify
plesk bin domain --remove DOMAIN            # delete
plesk bin domain --suspend DOMAIN           # suspend
plesk bin domain --on DOMAIN                # activate
```

Key create/update flags:
```
-ip IP                    assign IP(s)
-login LOGIN              system user
-passwd PASS              (prefer PSA_PASSWORD env)
-www-root PATH            document root (relative)
-service-plan NAME        assign service plan
-ssl true|false           SSL support
-ssl-redirect true|false  force HTTPS
-php true|false           PHP support
-php_handler_id ID        PHP handler (e.g. plesk-php83-fpm)
-shell SHELL|false        SSH shell
-hard_quota N[B|K|M|G|T]  disk quota (0=unlimited)
-seo-redirect non-www|www|none
-mail_service true|false
-webstat none|awstats|webalizer|goaccess
-description STRING
```

Subscription operations:
```bash
plesk bin subscription --switch-subscription SUB -service-plan NAME
plesk bin subscription --sync-subscription SUB
plesk bin domain --move DOMAIN -webspace-name TARGET
plesk bin domain --merge SUB -webspace-name TARGET
```

## Web server settings

```bash
plesk bin domain --update-web-server-settings DOMAIN \
  -nginx-proxy-mode true -nginx-serve-static true \
  -nginx-cache-enabled true -nginx-cache-timeout 5 \
  -nginx-client-max-body-size 134217728 \
  -nginx-http3-enabled true \
  -apache-restrict-follow-sym-links true
plesk bin domain --show-web-server-settings DOMAIN
```

## PHP

```bash
plesk bin domain --update-php-settings DOMAIN -settings /path/to/php.ini
plesk bin domain --show-php-settings DOMAIN
plesk bin php_handler --list                            # all handlers with id/version/path
plesk bin php_handler --reread                          # refresh from system
plesk bin php_handler --replace -old-id ID -new-id ID   # swap server-wide
plesk bin php_handler --get-usage -id ID
```

## Service plans

```bash
plesk bin service_plan --list
plesk bin service_plan --info NAME
plesk bin service_plan --create NAME [flags]
plesk bin service_plan --update NAME [flags]
plesk bin service_plan --remove NAME
plesk bin service_plan --duplicate NAME -duplicate-name NEWNAME
```

Key limit flags:
```
-disk_space N    -max_traffic N    -max_db N
-max_box N       -max_subdom N     -max_site N
-expiration N<Y|M|D>   -overuse block|not_suspend|notify|normal
-php_handler_id ID     -shell SHELL|false
-hosting true|false    -ssl true|false
```

## Subdomains

```bash
plesk bin subdomain --create SUB -webspace-name WEBSPC [hosting flags]
plesk bin subdomain --update SUB [flags]
plesk bin subdomain --remove SUB
plesk bin subdomain --list
```

## Domain aliases

```bash
plesk bin domalias --create ALIAS -domain PARENT [-mail true] [-web true] [-dns true]
plesk bin domalias --delete ALIAS
plesk bin domalias --info ALIAS
plesk bin domalias --rename ALIAS -new-name NEWFQDN
```

## Databases

```bash
plesk bin database --create DBNAME -domain DOMAIN [-type mysql|postgresql]
plesk bin database --remove DBNAME
plesk bin database --create-dbuser LOGIN -database DBNAME
plesk bin database --update-dbuser LOGIN [-passwd]
plesk bin database --remove-dbuser LOGIN
plesk bin database --upload DBNAME -dump-file FILE [-recreate]
plesk bin database --download DBNAME -dump-file FILE
plesk bin database --register DBNAME -domain DOMAIN    # register existing DB
```

Database servers:
```bash
plesk bin database-server --list
plesk bin database-server --create-server HOST:PORT -type mysql -admin LOGIN -passwd PASS
plesk bin database-server --set-default-server HOST:PORT -type mysql
```
