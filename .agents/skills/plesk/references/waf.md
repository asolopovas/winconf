# Plesk WAF / ModSecurity

Configure ModSecurity per domain with app-appropriate rules.

## Architecture

- Apache module `security2_module`. Server default in `/etc/apache2/plesk.conf.d/server.conf`.
- Per-domain settings in Plesk DB `WebServerSettingsParameters` table.
- Auto-generated into `/etc/apache2/plesk.conf.d/vhosts/DOMAIN.conf`.
- Rule sets in `/etc/apache2/modsecurity.d/rules/`.
- Control tool: `/opt/psa/admin/sbin/modsecurity_ctl`.

## Check status

```bash
/opt/psa/admin/sbin/modsecurity_ctl --status              # server backend
/opt/psa/admin/sbin/modsecurity_ctl --list-rulesets --enabled  # active rules
grep "SecRuleEngine" /etc/apache2/plesk.conf.d/server.conf    # server default

# Per-domain engine state from generated configs
for f in /etc/apache2/plesk.conf.d/vhosts/*.conf; do
  d=$(basename "$f" .conf)
  e=$(grep "SecRuleEngine" "$f" | head -1 | xargs)
  echo "$d: ${e:-inherits server default (On)}"
done

# Per-domain WAF settings from DB
plesk db -e "SELECT d.name, wsp.name, wsp.value \
  FROM WebServerSettingsParameters wsp, dom_param dp, domains d \
  WHERE dp.dom_id = d.id AND dp.param = 'webServerSettingsId' \
  AND wsp.webServerSettingsId = CAST(dp.val AS UNSIGNED) \
  AND wsp.name IN ('ruleEngine','filterByTag') ORDER BY d.name"
```

## How settings are stored

Each domain has `webServerSettingsId` in `dom_param`. WAF params in
`WebServerSettingsParameters`:

- `ruleEngine` -- `On`, `Off`, or `DetectionOnly`
- `filterByTag` -- newline-separated tags to REMOVE via `SecRuleRemoveByTag`

```sql
-- Get settings ID
SELECT dp.val FROM dom_param dp, domains d
WHERE dp.dom_id = d.id AND d.name = 'DOMAIN' AND dp.param = 'webServerSettingsId'

-- Get WAF settings
SELECT name, value FROM WebServerSettingsParameters
WHERE webServerSettingsId = WSID AND name IN ('ruleEngine', 'filterByTag')
```

## Modify WAF per domain

**Option A -- Plesk CLI (preferred when available):**
```bash
plesk bin domain --update-web-app-firewall DOMAIN -waf-rule-engine on|off|detection-only
```

**Option B -- Direct DB (for filterByTag or when CLI lacks the option):**
```sql
-- Enable WAF
UPDATE WebServerSettingsParameters SET value='On'
WHERE webServerSettingsId=WSID AND name='ruleEngine';

-- Set filter tags (INSERT if not exists, UPDATE if exists)
INSERT INTO WebServerSettingsParameters (webServerSettingsId, name, value)
VALUES (WSID, 'filterByTag', 'Tag1\nTag2\nTag3');
-- or UPDATE ... SET value='...' WHERE ...
```

Then rebuild and reload:
```bash
plesk sbin httpdmng --reconfigure-all
systemctl reload apache2 && systemctl reload nginx
```

Verify:
```bash
grep "SecRuleEngine\|SecRuleRemoveByTag" /etc/apache2/plesk.conf.d/vhosts/DOMAIN.conf
```

## App-specific WAF profiles

`filterByTag` lists tags whose rules are REMOVED. Tags NOT listed stay active.

### WordPress

Remove non-WP CMS rules. Keep WordPress, WPPlugin, SQLi, XSS, Backdoor active.
```
CWAF\nDomains\nDrupal\nFilterASP\nFilterGen\nFilterInFrame\nFilterOther\nFiltersEnd\nGeneric\nIncoming\nInitialization\nJComponent\nJoomla\nOther\nOtherApps\nPHPGen\nProtocol\nRequest\nRORGen\nWHMCS
```

### Laravel / Custom PHP

Same + remove WordPress/WPPlugin. Keep SQLi, XSS, Backdoor, FilterSQL, FilterPHP.
```
CWAF\nDomains\nDrupal\nFilterASP\nFilterGen\nFilterInFrame\nFilterOther\nFiltersEnd\nGeneric\nIncoming\nInitialization\nJComponent\nJoomla\nOther\nOtherApps\nPHPGen\nProtocol\nRequest\nRORGen\nWHMCS\nWordPress\nWPPlugin
```

### Nuxt / Node.js

Same + remove FilterPHP. Keep SQLi, XSS, Backdoor, FilterSQL.
```
CWAF\nDomains\nDrupal\nFilterASP\nFilterGen\nFilterInFrame\nFilterOther\nFilterPHP\nFiltersEnd\nGeneric\nIncoming\nInitialization\nJComponent\nJoomla\nOther\nOtherApps\nPHPGen\nProtocol\nRequest\nRORGen\nWHMCS\nWordPress\nWPPlugin
```

## Comodo Free tag reference

CMS-specific (remove if app not used):
`WordPress` `WPPlugin` `Drupal` `Joomla` `JComponent` `WHMCS` `RORGen`

Security (keep active):
`SQLi` `XSS` `Backdoor` `Bruteforce` `HTTP` `HTTPDoS` `FilterSQL` `FilterPHP`

Generic (typically removed to reduce false positives):
`CWAF` `Domains` `Generic` `Incoming` `Initialization` `FilterASP` `FilterGen`
`FilterInFrame` `FilterOther` `FiltersEnd` `Protocol` `Request` `Other` `OtherApps`
`PHPGen` `Agents` `AppsInitialization`

## Identify app type per domain

```bash
plesk ext wp-toolkit --list                                    # WordPress
find /var/www/vhosts -maxdepth 3 -name "artisan" -type f       # Laravel
find /var/www/vhosts -maxdepth 3 -name "nuxt.config.*" -type f # Nuxt
```

## Traps

- **Silent disable:** `ruleEngine=On` but `filterByTag` removes ALL tags (including SQLi,
  XSS, Backdoor) = WAF appears On in UI but does nothing. Always check filterByTag.
- **No CLI for filterByTag:** `plesk bin domain --update-web-app-firewall` only sets
  `ruleEngine`. For filterByTag, use direct DB updates + config rebuild.
- **MFA blocks panel API:** If MFA is enabled, can't curl Plesk panel pages. Use DB queries.
- **Config rebuild required:** DB changes have no effect until
  `plesk sbin httpdmng --reconfigure-all` runs.
