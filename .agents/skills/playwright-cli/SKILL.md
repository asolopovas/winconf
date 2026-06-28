---
name: playwright-cli
description: Automate browser interactions, test web pages and work with Playwright tests.
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
---

# Browser Automation with playwright-cli (v0.1.13+)

Accurate to installed **v0.1.13/0.1.14**. To see help for a command run
`playwright-cli --help <command>` (e.g. `playwright-cli --help open`) — **not**
`playwright-cli <command> --help`, which errors with exit code 2. Help/usage output may
arrive with a non-zero exit code; that is not a failure signal.
Global options: `--help [command]` · `--version` · `--json` (response as JSON) · `--raw` (result value only).

## Environment invariants (read first)

`playwright-cli` is **preinstalled and fully provisioned** — locally (Volta) and on servers
(global npm under the Plesk Node in `/opt/plesk/node/<latest>/bin`). On servers, browsers
live in the **shared root-owned directory `/opt/playwright-browsers`**
(`PLAYWRIGHT_BROWSERS_PATH`, set system-wide in `/etc/environment`).

- **`~/.cache/ms-playwright` is NOT where browsers live on servers.** It holds only
  playwright-cli session data, and may not exist at all. Finding it empty or missing
  means nothing. To check browser provisioning, run:
  `ls "$PLAYWRIGHT_BROWSERS_PATH"` — you should see `chromium-<rev>` directories.
- **Never install browsers, by any route.** Not `playwright-cli install-browser`, not
  `npx playwright install`, and **never** by invoking internals such as
  `.../node_modules/playwright-core/cli.js install`. As a vhost user you cannot write to
  `/opt/playwright-browsers` or the global npm root, so any install attempt either fails
  or downloads a useless private copy into your home directory.
- **If the environment looks broken, stop and report — do not repair it.** Symptoms like
  `PLAYWRIGHT_BROWSERS_PATH` unset, `/opt/playwright-browsers` missing/empty,
  `playwright-cli` not on PATH, or `/opt/plesk/node/<N>/bin/node: No such file or
  directory` are provisioning problems only the server admin (root) can fix, by running
  `~/dotfiles/scripts/inst/inst-playwright-cli.sh` **as root**. State the exact symptom in
  your final answer and continue with whatever else you can do. Never install or switch
  Node versions, and never hand-patch wrappers.
- **Headless is the default.** No flag needed; `--headed` is only for desktop sessions.
- **On servers always `open --browser=chromium`.** The default `open` uses the branded
  Chrome channel (`/opt/google/chrome/chrome`), which servers don't have. The error
  `Chromium distribution 'chrome' is not found` means you forgot `--browser=chromium` —
  it does **not** mean you should install Chrome or any browser.

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

Core: `open [url]` · `attach [name]` · `close` · `detach` · `goto <url>` · `type <text>` ·
`click <ref> [button]` · `dblclick <ref> [button]` · `fill <ref> <text>` ·
`drag <startRef> <endRef>` · `drop <ref> <file...>` · `hover <ref>` · `select <ref> <val>` ·
`upload <file...>` (absolute paths) · `check <ref>` · `uncheck <ref>` · `snapshot` ·
`eval <func> [ref]` · `dialog-accept [prompt]` · `dialog-dismiss` · `resize <w> <h>` · `delete-data`

Nav: `go-back` · `go-forward` · `reload`
Keyboard: `press <key>` · `keydown <key>` · `keyup <key>`
Mouse: `mousemove <x> <y>` · `mousedown [button]` · `mouseup [button]` · `mousewheel <dx> <dy>`
Save: `screenshot [ref]` · `pdf`
Tabs: `tab-list` · `tab-new [url]` · `tab-close [index]` · `tab-select <index>`
Storage: `state-load <file>` · `state-save [file]` · `cookie-list|get|set|delete|clear` ·
`localstorage-list|get|set|delete|clear` · `sessionstorage-list|get|set|delete|clear`
Network: `requests` · `request <n>` · `request-headers <n>` · `request-body <n>` ·
`response-headers <n>` · `response-body <n>` · `route <pattern>` · `route-list` ·
`unroute [pattern]` · `network-state-set <online|offline>`
DevTools: `console [min-level]` · `run-code <code>` · `tracing-start` · `tracing-stop` ·
`video-start` · `video-stop` · `video-chapter` · `show` (dashboard) ·
`highlight [target]` · `generate-locator <target>`
Test debug: `pause-at <file:line>` · `resume` · `step-over`
Install (root-only provisioning — never run these; see Environment invariants): `install` · `install-browser`
Sessions: `list` · `close-all` · `kill-all`

## Key options (per command)

- `open`: `--browser=chromium|chrome|firefox|webkit|msedge` (servers: always `chromium`) ·
  `--headed` · `--persistent` · `--profile=<dir>` · `--config=<path>`
- `attach`: `--cdp=<url>` · `--endpoint=<url>` · `--extension[=browser]` · `--session=<name>`
- `fill` / `type`: `--submit` (press Enter after)
- `click`: `--modifiers=<keys>`
- `snapshot`: `--filename=<file>` (write to file) · `--depth=<n>` · `--boxes` (bounding boxes)
- `screenshot`: `--filename=<file>` · `--full-page`
- `pdf`: `--filename=<file>`
- `eval`: `<func>` is `() => {...}` / `(el) => {...}` / a bare expression; result follows
  `### Result` (or use global `--raw` to get only the value)
- `console`: `[min-level]` (info default; severe levels included) · `--clear`
- `requests`: `--static` (include images/fonts/scripts) · `--filter=<regexp>` · `--clear`
- `route`: `--status` · `--body` · `--content-type` · `--header "Name: value"` (repeatable) ·
  `--remove-header=<csv>`
- `cookie-set`: `--domain --path --expires --httpOnly --secure --sameSite`

## run-code (advanced)

A single function, wrapped in `(...)` and called with `page`. No `require`/`import`.
Inline it or load from a file with `--filename`.

```bash
playwright-cli run-code "async page => { await page.context().grantPermissions(['geolocation']); }"
playwright-cli run-code --filename=script.js
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

## Gotchas

- Prefer `--raw` (value only) or `--json` for parseable output; without them the `eval`
  value follows `### Result`.
- `snapshot` stdout is only a link — always use `--filename` and read that file.
- On servers, plain `open` fails with `Chromium distribution 'chrome' is not found` —
  use `open --browser=chromium`; never install Chrome (see Environment invariants).
- **Refs belong to the latest snapshot.** Snapshot again right before acting after any
  nav/reload/DOM change; counters renumber on reload (a canvas ref `f2e18` becomes `f4e18`).
- **iframe content** (e.g. the WordPress block editor, embedded apps): target it by snapshot
  ref. Frame refs are prefixed `fNeN` (e.g. `f2e18`); pass the bare ref to actions (`click f2e18`).
  For the WordPress block editor specifically, see [references/wordpress-block-editor.md](references/wordpress-block-editor.md).
- Call `dialog-accept`/`dialog-dismiss` after the action that opens a dialog (e.g. leaving an
  editor fires `beforeunload`); a pending dialog must exist when you call it.
- `fill`/`select`/`check` accept only snapshot refs (`e12`), not CSS; `click`/`hover` accept CSS.
- There is no `network` command — use `requests` (list) and `request <n>` (detail).

## Installation (root-only provisioning)

Already installed everywhere. If genuinely missing or broken (e.g. stale Node path):

- **As root** (or locally): re-run the installer — never `npm install` pieces by hand or
  switch Node versions:

  ```bash
  ~/dotfiles/scripts/inst/inst-playwright-cli.sh   # latest CLI + skills + shared chromium
  ```

- **As a vhost/subscription user**: you cannot fix it (the installer refuses to run, and
  the shared paths are root-owned). Verify with `playwright-cli --version` and
  `ls "$PLAYWRIGHT_BROWSERS_PATH"`, then report the exact failing command and output to
  the server admin. Do not attempt any workaround install.

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
