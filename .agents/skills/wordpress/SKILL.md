---
name: wordpress
description: "Master skill for operating, debugging, testing, and securing WordPress (7.0 'Armstrong') from the shell and an automated browser. Start here, then open the targeted reference for diagnostics, debugging, WP-CLI, authenticated login, the block editor, WooCommerce, or penetration testing."
---

# WordPress

Operate, debug, test, and secure WordPress. Read the shared context and conventions below
(they apply to every reference), then open the targeted reference for your task.

## Pick your task

| Goal | Reference |
|------|-----------|
| Triage "is it up / what's broken" (read-only) | [references/diagnostics.md](references/diagnostics.md) |
| Root-cause a specific error, fatal, or slow page | [references/debugging.md](references/debugging.md) |
| Shell admin/data ops + command quick reference (source of truth) | [references/wp-cli.md](references/wp-cli.md) |
| Get an authenticated wp-admin browser session | [references/test-login.md](references/test-login.md) |
| Drive the block editor (Gutenberg) | [references/gutenberg.md](references/gutenberg.md) |
| Build or extend a WooCommerce store | [references/woocommerce.md](references/woocommerce.md) |
| Security assessment (authorized only) | [references/penetration-testing.md](references/penetration-testing.md) |

Browser primitives (snapshots, refs, iframes, dialogs) live in the **playwright-cli** skill.
Block-editor browser driving is documented there too:
`playwright-cli/references/wordpress-block-editor.md`.

## Shared context — WP 7.0 "Armstrong" (released 20 May 2026)

- **Floors:** PHP 7.4 min (8.3+ recommended); MySQL 8.0 / MariaDB 10.6 min. Sites below the
  floors won't auto-update and may fatal — expect stale, unpatched installs.
- Core ships the **AI Client**, **Connectors API** (Settings > Connectors), and the
  **Abilities API** (`wp_register_ability`, REST `wp-abilities/v1`). WordPress is natively agentic.
- Verify live REST namespaces at `/wp-json/` — do **not** assume `ai/v1`. Core also adds
  `wp-sync/v1` and `wp-site-health/v1`.
- The post editor is an **iframe** by default (see the gutenberg reference).
- Autoload column values are `on`/`auto`/`auto-on` (WP 6.6+), **not** `yes`/`no`.

## Conventions (all references)

- Run from the WP root, or pass `--path=/path/to/wp` to every `wp` command.
- Prefer `wp eval 'global $wpdb; ...'` over `wp db query` — it runs through PHP/PDO (no
  `mysql` client needed) and resolves the table prefix for you via `$wpdb->options` / `$wpdb->posts`.
- The table prefix is **not** always `wp_` (`wp config get table_prefix`).
- Destructive ops (`search-replace`, `db query` writes, bulk `post delete`): `wp db export`
  first; on production, confirm scope with the user.

## Typical routes

- Broken site: **diagnostics** (triage) -> **debugging** (root cause) -> **wp-cli** (apply fix).
- UI/editor test: **test-login** (session) -> **gutenberg** (drive editor) -> **wp-cli** (verify persisted).
- Integrity failure or injected code: **penetration-testing**.

## Keep this skill current

When a session surfaces a durable, reusable nuance — a WP 7.0 behavior change, a verified
command/flag, a recurring trap and its fix, a corrected assumption — update this skill in
`~/dotfiles/.agents/skills/wordpress/` before finishing:

- Put the fact in the **right place**: shared/cross-cutting -> this `SKILL.md`; task-specific ->
  the matching `references/*.md`; browser-driving -> the playwright-cli reference.
- Edit in place; do not duplicate. If a fact already exists, correct it rather than re-adding.
- **Prune as you add:** delete anything the new nuance proves wrong, stale, or irrelevant
  (outdated versions/flags, disproven assumptions, dead workarounds). Net size should stay
  flat or shrink — updating is editing, not appending.
- Keep the style: concise, ASCII-only, verified commands, no filler. Mark unverified guesses.
- Only record durable knowledge, not one-off site specifics or secrets.
