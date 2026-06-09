---
name: playwright-cli
description: Automate browser interactions, test web pages and work with Playwright tests.
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
---

# Browser Automation with playwright-cli (v0.1.0)

Accurate to installed **v0.1.0**. Run `playwright-cli --help [command]` to confirm any option.
Global options are only `--help [command]` and `--version` — there is **no** `--raw` or `--json`.

## Fast workflow

```bash
playwright-cli open https://example.com    # open browser (+ optional url)
playwright-cli snapshot --filename=/tmp/s.yml   # YAML refs -> FILE (stdout is only a link)
playwright-cli fill e5 "user@example.com" --submit   # fill by ref, Enter after
playwright-cli click e3                     # act on refs from the snapshot
playwright-cli eval "document.title"        # value prints on the line after "### Result"
playwright-cli close
```

Refs (`e5`) come from the snapshot. `click`/`hover`/etc. also accept CSS or locators
(`"#id"`, `getByRole('button',{name:'Save'})`); `fill`/`select`/`check` need a ref.

## Inspect loop (snapshot → grep → act)

Refs are valid only for the snapshot you just took. Re-snapshot after **every**
navigation, reload, or DOM change, then act before the page mutates again:

```bash
playwright-cli goto <url>; sleep 2
playwright-cli snapshot --filename=/tmp/s.yml      # refs go to the FILE
grep -niE 'button "Save"|Thickness' /tmp/s.yml     # locate the ref you need
playwright-cli click e66                            # act immediately
```

For the WordPress block editor (auth + editor automation), use the **wordpress** skill (its
test-login and gutenberg references), then drive the same session with the loop above.
Editor-specific browser mechanics: [references/wordpress-block-editor.md](references/wordpress-block-editor.md).

## Commands

Core: `open [url]` · `close` · `goto <url>` · `type <text>` · `click <ref> [button]` ·
`dblclick <ref> [button]` · `fill <ref> <text>` · `drag <startRef> <endRef>` · `hover <ref>` ·
`select <ref> <val>` · `upload <file...>` (absolute paths) · `check <ref>` · `uncheck <ref>` ·
`snapshot` · `eval <func> [ref]` · `dialog-accept [prompt]` · `dialog-dismiss` ·
`resize <w> <h>` · `delete-data`

Nav: `go-back` · `go-forward` · `reload`
Keyboard: `press <key>` · `keydown <key>` · `keyup <key>`
Mouse: `mousemove <x> <y>` · `mousedown [button]` · `mouseup [button]` · `mousewheel <dx> <dy>`
Save: `screenshot [ref]` · `pdf`
Tabs: `tab-list` · `tab-new [url]` · `tab-close [index]` · `tab-select <index>`
Storage: `state-load <file>` · `state-save [file]` · `cookie-list|get|set|delete|clear` ·
`localstorage-list|get|set|delete|clear` · `sessionstorage-list|get|set|delete|clear`
Network: `route <pattern>` · `route-list` · `unroute [pattern]` · `network`
DevTools: `console [min-level]` · `run-code <code>` · `tracing-start` · `tracing-stop` ·
`video-start` · `video-stop`
Install: `install` · `install-browser`
Sessions: `list` · `close-all` · `kill-all`

## Key options (per command)

- `open`: `--browser=chrome|firefox|webkit|msedge` · `--headed` · `--persistent` ·
  `--profile=<dir>` · `--extension` (connect to a browser extension) · `--config=<path>`
- `fill` / `type`: `--submit` (press Enter after)
- `click`: `--modifiers=<keys>`
- `snapshot`: `--filename=<file>` (writes markdown/YAML to file; **only** option — no depth/ref/box)
- `screenshot`: `--filename=<file>` · `--full-page`
- `pdf`: `--filename=<file>`
- `eval`: `<func>` is `() => {...}` / `(el) => {...}` / a bare expression; result follows `### Result`
- `console`: `[min-level]` (info default; severe levels included) · `--clear`
- `network`: `--static` (include images/fonts/scripts) · `--clear`
- `route`: `--status` · `--body` · `--content-type` · `--header "Name: value"` (repeatable) ·
  `--remove-header=<csv>`
- `cookie-set`: `--domain --path --expires --httpOnly --secure --sameSite`

## run-code (advanced)

Inline single function only — **no `--filename`** in v0.1.0. Wrapped in `(...)` and called with `page`.
No `require`/`import`. To run a file, inline it.

```bash
playwright-cli run-code "async page => { await page.context().grantPermissions(['geolocation']); }"
playwright-cli run-code "$(cat script.js)"
```

See [references/running-code.md](references/running-code.md) for geolocation, frames, downloads, waits.

## Sessions

```bash
playwright-cli -s=mysession open example.com --persistent
playwright-cli -s=mysession click e6
playwright-cli -s=mysession close
playwright-cli list          # list sessions
playwright-cli close-all      # close all
playwright-cli kill-all       # kill stale/zombie processes
```

## Targeting elements

```bash
playwright-cli click e15                              # ref from snapshot (preferred)
playwright-cli click "#main > button.submit"          # css selector
playwright-cli click "getByRole('button',{name:'Submit'})"   # role locator
playwright-cli click "getByTestId('submit-button')"   # test id
playwright-cli eval "el => el.getAttribute('data-x')" e5   # read attrs not in snapshot
```

## Gotchas (v0.1.0)

- No global `--raw`/`--json`; parse normal output (`eval` value follows `### Result`).
- `snapshot` stdout is only a link — always use `--filename` and read that file.
- **Refs belong to the latest snapshot.** Snapshot again right before acting after any
  nav/reload/DOM change; counters renumber on reload (a canvas ref `f2e18` becomes `f4e18`).
- **iframe content** (e.g. the WordPress block editor, embedded apps): target it by snapshot
  ref. Frame refs are prefixed `fNeN` (e.g. `f2e18`); pass the bare ref to actions (`click f2e18`).
  For the WordPress block editor specifically, see [references/wordpress-block-editor.md](references/wordpress-block-editor.md).
- Call `dialog-accept`/`dialog-dismiss` after the action that opens a dialog (e.g. leaving an
  editor fires `beforeunload`); a pending dialog must exist when you call it.
- `fill`/`select`/`check` accept only snapshot refs (`e12`), not CSS; `click`/`hover` accept CSS.
- These are **not** commands in v0.1.0 (newer builds only): `drop`, `requests`/`request`,
  `attach`/`detach`, `show`, `generate-locator`, `highlight`, `video-chapter`. Use `network`
  instead of `requests`, and `open --extension` instead of `attach`.

## Installation

```bash
npx --no-install playwright-cli --version    # use local copy if present (then prefix npx)
npm install -g @playwright/cli@latest        # else install globally
```

## Specific tasks

- Running/debugging Playwright tests — [references/playwright-tests.md](references/playwright-tests.md)
- Request mocking — [references/request-mocking.md](references/request-mocking.md)
- Running code — [references/running-code.md](references/running-code.md)
- Sessions — [references/session-management.md](references/session-management.md)
- Spec-driven testing — [references/spec-driven-testing.md](references/spec-driven-testing.md)
- Storage state — [references/storage-state.md](references/storage-state.md)
- Test generation — [references/test-generation.md](references/test-generation.md)
- Tracing — [references/tracing.md](references/tracing.md)
- Video recording — [references/video-recording.md](references/video-recording.md)
- Element attributes — [references/element-attributes.md](references/element-attributes.md)
- WordPress block editor — [references/wordpress-block-editor.md](references/wordpress-block-editor.md) (+ the **wordpress** skill)
</content>
</invoke>
