# WP-CLI Workflows

**Purpose** — Drive WordPress from the shell and provide the source-of-truth command quick
reference the other references hand off to. Prefer this over UI clicking for accuracy and speed.

**Inputs** — Shell access to the host/container; WP root (or `--path=/path/to/wp`); `wp` on
`PATH` (install: download `wp-cli.phar`, `chmod +x`, move to `/usr/local/bin/wp`). See SKILL.md
conventions for `wp eval` vs `wp db query` and table-prefix handling.

## Quick reference

Run `wp --path=<wp> ...` (path omitted below for brevity).

```bash
# Core / health
wp core version --extra                 # version + update channel
wp core check-update                    # pending core updates
wp core verify-checksums                # detect tampered core files
wp cli info                             # PHP binary, config paths

# Config / options
wp config get table_prefix
wp option get siteurl ; wp option get home
wp option update blogname "New Name"

# Plugins / themes
wp plugin list --status=active --fields=name,version,update
wp plugin deactivate <slug> ; wp plugin activate <slug>
wp theme list --fields=name,status,version
wp plugin verify-checksums --all        # tampered plugin files

# Users
wp user list --fields=ID,user_login,roles
wp user create bob bob@x.test --role=editor --user_pass="$(wp eval 'echo wp_generate_password(24,true,false);')"
wp user update <id> --user_pass=...     # reset password

# Posts / meta (source of truth for block + bound-meta state)
wp post list --post_type=product --fields=ID,post_title
wp post get <id> --field=post_content
wp post meta get <id> <key>
wp post meta update <id> <key> '["a","b"]' --format=json
wp post meta list <id> --format=json

# Search-replace (migrations) — ALWAYS dry-run first
wp search-replace 'old.test' 'new.test' --dry-run --report-changed-only
wp search-replace 'old.test' 'new.test' --precise --skip-columns=guid

# Database
wp db check ; wp db size --tables
wp db export backup.sql                 # before risky changes

# Cache / rewrite / cron
wp cache flush ; wp transient delete --all
wp rewrite flush --hard                 # fix 404s after permalink/structure changes
wp cron event list ; wp cron event run --due-now

# Maintenance / scaffolding
wp maintenance-mode status|activate|deactivate
wp eval 'echo home_url();'              # run arbitrary PHP in WP context
wp eval 'echo wp_get_environment_type();'   # local|development|staging|production (default production)
wp shell                                # interactive REPL

# Optional packages (not bundled) — install once if needed:
wp package install wp-cli/profile-command   # then: wp profile stage --all  (find slow hooks)
wp package install wp-cli/doctor-command    # then: wp doctor check --all    (health rules)
```

## Autoload audit

Slow home is often bloated autoloaded options. WP 6.6+ changed the `autoload` column values
from `yes`/`no` to `on`/`off`/`auto`/`auto-on`/`auto-off` — `autoload='yes'` now matches
**nothing**. Match the live set (portable, prefix-safe):

```bash
wp eval "global \$wpdb; echo \$wpdb->get_var(\"SELECT ROUND(SUM(LENGTH(option_value))/1024,1) FROM \$wpdb->options WHERE autoload IN ('yes','on','auto','auto-on')\").' KB autoloaded'.PHP_EOL;"
wp eval "global \$wpdb; foreach(\$wpdb->get_results(\"SELECT option_name,LENGTH(option_value) b FROM \$wpdb->options WHERE autoload IN ('yes','on','auto','auto-on') ORDER BY b DESC LIMIT 10\") as \$r){echo \$r->option_name.': '.\$r->b.PHP_EOL;}"
```

## Troubleshooting one-liners

```bash
wp plugin list --status=active --field=name | xargs -I{} sh -c 'wp plugin deactivate {} && echo "off:{}"'  # bisect a fatal
wp option get active_plugins --format=json   # if admin is down (prefix-safe, no SQL)
wp option update blog_public 0          # ensure noindex on staging
wp eval 'var_dump(get_option("template"), get_option("stylesheet"));'        # active theme sanity
```

## Handoff

- Error/white screen with unknown cause -> [debugging.md](debugging.md).
- "Is the site healthy?" fast triage -> [diagnostics.md](diagnostics.md).
- Assert UI/editor behavior -> [test-login.md](test-login.md) then [gutenberg.md](gutenberg.md).
