# WordPress Gutenberg (Block Editor)

**Purpose** — Inspect and manipulate the block editor accurately, using stable core WordPress
APIs (`wp.data`) for state and `playwright-cli` for real user input.

**Inputs** — An authenticated editor session ([test-login.md](test-login.md)) on a local/dev
site, `playwright-cli` driving it with the editor open
(`.../post.php?post=<ID>&action=edit`), and `wp` for out-of-band verification ([wp-cli.md](wp-cli.md)).

**Browser driving** (iframe refs, snapshot -> grep -> act, asserting control state) lives in
`playwright-cli/references/wordpress-block-editor.md`. This reference covers the
WordPress-specific state APIs and the rule for when to use them vs. clicking.

## Fast path — read / select / save via core `wp.data`

`playwright-cli eval` runs in the page; `wp.data` is available there. Blocks nest, so walk
`innerBlocks` recursively. This is faster and exact for reading, asserting, selecting, saving.

```bash
# READ a block's attributes by name (recursive walk handles nested blocks)
playwright-cli eval "() => { const all=[]; const walk=bs=>bs.forEach(b=>{all.push(b);walk(b.innerBlocks)}); walk(wp.data.select('core/block-editor').getBlocks()); const b=all.find(x=>x.name==='<namespace/block>'); return JSON.stringify(b.attributes); }"

# SELECT a block (this populates its inspector panels)
#   ...same walk... wp.data.dispatch('core/block-editor').selectBlock(b.clientId)
#   confirm: wp.data.select('core/block-editor').getSelectedBlockClientId()

# READ post meta the editor has staged (entity record, core stable)
playwright-cli eval "() => { const s=wp.data.select('core/editor'); return JSON.stringify(wp.data.select('core').getEditedEntityRecord('postType', s.getCurrentPostType(), s.getCurrentPostId()).meta); }"

# SAVE programmatically, then poll until done
playwright-cli eval "() => { wp.data.dispatch('core/editor').savePost(); return 'saving'; }"
# poll: wp.data.select('core/editor').isSavingPost()  // true -> false when complete
```

## Accuracy rule — when to click instead of `wp.data`

`updateBlockAttributes` / `editEntityRecord` change state **without firing the block's React
control handlers**. Side effects you may be testing — validation, derived state, and **meta
that a control syncs on change** — will NOT run. **Verified:** setting `fieldValues` via
`updateBlockAttributes` left the bound post meta unchanged.

- Testing real user behavior or a control's side effects -> **drive the UI** (see the
  playwright-cli block-editor reference).
- Reading, asserting, selecting, or saving -> use `wp.data` (faster, exact).

## Verify out-of-band (source of truth)

```bash
wp post meta get <id> <key>                       # confirm persisted value
wp post get <id> --field=post_content | head      # confirm serialized block markup
curl -sS "$(wp option get siteurl)/?p=<id>"       # confirm front-end render
```

## Handoff

- Need an authenticated session -> [test-login.md](test-login.md).
- Browser primitives / editor driving -> **playwright-cli** (and its `wordpress-block-editor.md`).
- Confirm/inspect persisted data -> [wp-cli.md](wp-cli.md).
- Editor throws an error or save fails -> [debugging.md](debugging.md) (`SCRIPT_DEBUG`, console, REST nonce).
