# WordPress Diagnostics

**Purpose** — Rapid triage: classify a problem (down, slow, errors, config drift) and point
at the right fix, without changing anything. First response to "the site is broken / slow /
acting weird." For root-causing a specific PHP error, go to [debugging.md](debugging.md).

**Inputs** — WP root or `--path`, shell access, site URL. Read-only; make no changes.

## Triage checklist

```bash
WP=/path/to/wp
# 1. Installed and reachable?
wp --path=$WP core is-installed && echo "core ok"
wp --path=$WP core version --extra | head -1            # confirm 7.0 "Armstrong"
URL=$(wp --path=$WP option get siteurl)
curl -sS -o /dev/null -w "home: %{http_code} %{time_total}s\n" "$URL"
curl -sS -o /dev/null -w "admin: %{http_code}\n" "$URL/wp-admin/"

# 2. Core/file integrity + versions
wp --path=$WP core verify-checksums || echo "CORE FILES MODIFIED"
wp --path=$WP core check-update

# 3. Plugins/themes: updates, tampering, active theme sanity
wp --path=$WP plugin list --fields=name,status,version,update
wp --path=$WP plugin verify-checksums --all 2>&1 | tail -5
wp --path=$WP eval 'var_dump(get_option("template"), get_option("stylesheet"));'

# 4. Database reachable + healthy
wp --path=$WP db check ; wp --path=$WP db size

# 5. Config drift / environment
wp --path=$WP config get WP_DEBUG                       # empty/false = off
wp --path=$WP eval 'echo wp_get_environment_type()."\n";'   # NOT a wp-config constant by default
wp --path=$WP option get home ; wp --path=$WP option get siteurl   # mismatch => redirect loops

# 6. WP 7.0 floor compliance (see SKILL.md shared context)
wp --path=$WP eval 'printf("PHP %s (min 7.4, rec 8.3+)%s", PHP_VERSION, PHP_EOL);'
wp --path=$WP eval 'global $wpdb; echo "DB ".$wpdb->db_version()." (min MySQL 8.0 / MariaDB 10.6)".PHP_EOL;'

# 7. Slow home? Audit autoloaded options (see wp-cli.md "Autoload audit")
# 8. Recent errors (if logging on)
tail -n 40 "$WP/wp-content/debug.log" 2>/dev/null
```

## Reading the results

| Symptom | Likely cause | Next |
|---------|--------------|------|
| home 500 / white screen | PHP fatal (plugin/theme) | [debugging.md](debugging.md) |
| home 200 but admin 500 | admin-only plugin/memory | [debugging.md](debugging.md) |
| Redirect loop | `home`/`siteurl` mismatch or SSL | [wp-cli.md](wp-cli.md) `option update` |
| 404 on all but home | rewrite rules | `wp rewrite flush --hard` ([wp-cli.md](wp-cli.md)) |
| Slow home (>1s) | autoloaded options / queries | autoload audit in [wp-cli.md](wp-cli.md) |
| `verify-checksums` fail | tampered/compromised files | [penetration-testing.md](penetration-testing.md) |
| DB check error | DB down/corruption | `db repair` via [wp-cli.md](wp-cli.md) |
| Won't auto-update to 7.0 | PHP < 7.4 or MySQL < 8.0 | upgrade host stack before retrying |
