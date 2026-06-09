# WordPress Test Login

**Purpose** — Get a valid, authenticated wp-admin browser session (real form login, real
`wp_rest` nonce) for `playwright-cli`, without touching real users. Local/dev hosts only.

**Inputs** — WordPress path on a local host (`*.test`, `*.local`, `localhost`, `127.0.0.1`);
`wp` and `playwright-cli` on `PATH`.

## 1. Provision a throwaway admin

Run directly. The password stays in `$PW` and is never printed.

```bash
WP=/path/to/wordpress ; U=pi-test-admin
# Local-only guard — if this prints REFUSING, stop: do not provision on a production host.
HOST=$(wp --path=$WP option get siteurl | sed -E 's#^https?://##; s#/.*##')
case "$HOST" in *.test|*.local|localhost|127.0.0.1) echo "local host OK: $HOST";; *) echo "REFUSING non-local host: $HOST";; esac
# Random password; create the user, or rotate its password if it already exists.
PW=$(wp --path=$WP eval 'echo wp_generate_password(24,true,false);')
wp --path=$WP user create "$U" "$U@example.test" --role=administrator --user_pass="$PW" 2>/dev/null \
  || wp --path=$WP user update "$U" --user_pass="$PW" --role=administrator
```

## 2. Log in via a real form post

Use the snapshot -> grep -> act loop (refs renumber on each snapshot):

```bash
playwright-cli open >/dev/null 2>&1 || true
playwright-cli goto "$(wp --path=$WP eval 'echo wp_login_url();')"
playwright-cli snapshot --filename=/tmp/wp-login.yml
grep -niE 'textbox "Username|textbox "Password|button "Log In"' /tmp/wp-login.yml   # get the refs
playwright-cli fill <user-ref> "$U"        # fill takes the value as a clean shell arg
playwright-cli fill <pass-ref> "$PW"
playwright-cli click <login-ref>
playwright-cli eval 'location.href'        # expect /wp-admin/, NOT wp-login.php
```

Then drive the same session, e.g.:

```bash
playwright-cli goto "http://$HOST/wp-admin/post.php?post=<ID>&action=edit"
playwright-cli snapshot --filename=/tmp/edit.yml     # YAML to the file, not stdout
```

## Rules

- Never echo `$PW`.
- Use a **real form login** (above). Do **not** inject `wp_generate_auth_cookie` cookies —
  those tokens aren't registered sessions, so REST nonces 403 and editor saves fail silently.

## Cleanup

```bash
playwright-cli close
wp --path=$WP user delete pi-test-admin --reassign=1 --yes
```

## Handoff

- Logged in and need to drive the block editor -> [gutenberg.md](gutenberg.md).
- Browser primitives (snapshot refs, dialogs, iframes) -> **playwright-cli**.
- Verify what the UI persisted -> [wp-cli.md](wp-cli.md) (`wp post meta get`).
- Editor/REST errors during a test -> [debugging.md](debugging.md).
