# Driving the WordPress Block Editor (Gutenberg)

Browser-automation mechanics for the WordPress block editor. For WordPress state APIs
(`wp.data` read/select/save), the click-vs-`wp.data` accuracy rule, and out-of-band
verification, see the **wordpress** skill's `references/gutenberg.md`. For an authenticated
session, use the **wordpress** skill's `references/test-login.md`.

## WP 7.0 reality

- The post editor canvas is an **iframe by default** (core 7.0): page-level CSS/text selectors
  do **not** reach block content. Target it by snapshot frame ref. The iframe-ref and
  snapshot -> grep -> act rules are in the main SKILL.md (Inspect loop, Gotchas) — they apply
  here unchanged.
- Wait `sleep 3` after `goto` for editor hydration (longer than the generic `sleep 2`).

## UI path — exercise a control end-to-end

```bash
S=/tmp/wp-snapshot.yml
playwright-cli snapshot --filename=$S
grep -niE 'heading "<block title>"' $S         # find the block's canvas ref (fNeN)
playwright-cli click f4e18                       # select block -> inspector populates
playwright-cli click 'role=tab[name="Block"]'    # open the Block inspector tab
sleep 1; playwright-cli snapshot --filename=$S
# Expand the panel if collapsed, then click controls:
#   button "Toggle panel: <name>"  ->  the control buttons
playwright-cli click e506 ; playwright-cli click e515
playwright-cli snapshot --filename=$S
grep -niE '\[pressed\]' $S                        # assert control state
```

If the Block tab shows "No block selected", re-select the block (click its canvas ref) and retry.

## Reading / selecting / saving block state

Don't script that through the DOM. The fast, exact path is `playwright-cli eval` with core
`wp.data` — those snippets and the rule for when a real UI click is required instead live in
the **wordpress** skill's `references/gutenberg.md`. Use the UI path above only when you need
a control's real handlers to fire.
