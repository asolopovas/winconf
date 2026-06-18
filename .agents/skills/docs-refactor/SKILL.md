---
name: docs-refactor
description: Refactor and clean up documentation — make docs concise, remove repetition and fluff, fix broken links, split bloated files, and align them to agent-harness doc principles. Use when asked to refactor docs, clean up docs, tighten/trim documentation, dedupe docs, or audit a docs tree.
---

# docs-refactor

Refactor a docs tree to be **as concise as possible** — remove repetition and
fluff, fix structure, and align to the agent-harness principles in
`principles.md`.

**Read every in-scope doc end to end, then refactor. The audit is a
cross-check, not the decision.** The driver catches only mechanical problems
(line counts, filler density, exact-duplicate lines, broken links, heading
levels). It's blind to what actually makes docs good: verbose prose under the
threshold, the *same idea* reworded across files, content in the wrong file,
sections that should merge/split/reorder, an `AGENTS.md` drifted into a manual,
prose that no longer matches the code. **A clean audit means the mechanical
floor is met — not that nothing needs work.** Never call a tree done on the
audit alone; that verdict is valid only after reading the prose.

Paths below are relative to the **target repo root** (the docs you're cleaning).
The driver lives in this skill dir.

## Run the audit (mechanical cross-check)

```bash
node <skill-dir>/audit.mjs docs          # scan the docs/ tree
node <skill-dir>/audit.mjs . --json      # whole repo, machine-readable
node <skill-dir>/audit.mjs README.md docs --top=30   # specific paths + more rows
```

`<skill-dir>` is `~/.claude/skills/docs-refactor` (or this file's directory).
Flags: `--json`, `--max-lines=N` (bloat threshold, default 400), `--top=N`
(rows per section, default 12). Exit code is `1` when findings exist, `0` clean —
usable as a CI gate.

It prints six prioritized sections (worst-first):

| Section | Means | Action |
|---|---|---|
| **BLOAT** | file > `--max-lines` | split by topic, or cut to essentials |
| **FLUFF** | filler-word density (`in order to`, `simply`, `utilize`, `just`, `very`…) | rewrite tighter; cut hedging |
| **DUPLICATION** | a prose line appears in 2+ places | keep one canonical copy, link the rest |
| **BROKEN LINKS** | local `[..](path.md)` doesn't resolve | fix the path or drop the link |
| **STRUCTURE** | missing/duplicate H1, heading-level jumps | one H1 per file; no skipped levels |
| **STALE MARKERS** | `TODO`/`FIXME`/old dates | resolve or delete |

## Refactor loop

1. **Enumerate + audit** — list every doc in scope (`**/*.md`, minus
   `node_modules`/vendored trees); run the audit once for the baseline.
2. **Read all of them** end to end. Note (file:line) every issue a human editor
   would act on, audit-flagged or not:
   - verbose, hedged, or heading-restating prose;
   - the *same concept* in two places (semantic dup the line-matcher misses) →
     one home, link the rest;
   - content in the wrong file; sections to merge/split/reorder;
   - a map doc (`AGENTS.md`) grown instructions it should link to instead;
   - prose that no longer matches the code/commands/layout — verify, don't trust.
3. **Fix** mechanical findings in priority order (broken links → duplication →
   bloat → fluff → structure → stale markers; links/dupes shift file boundaries,
   so first) **plus every issue you found by reading.**
4. **Apply `principles.md`:** docs are the repo's source of truth; `AGENTS.md`
   is a short *map*, not a manual; prefer short, linked docs over monoliths.
5. **Re-audit + re-read** changed docs. Aim for exit 0, or a short, deliberate
   list of accepted findings.
6. **Report** — what you read, cut (lines before/after), merged/moved, and any
   findings kept and why.

## Editing rules

- **Cut, don't pad.** Every sentence earns its place. Delete throat-clearing
  ("It is important to note…"), hedges ("basically", "just"), and restatements.
- **One source of truth per fact.** When the audit flags duplication,
  consolidate to one location and replace the others with a link.
- **Preserve meaning and commands.** Tightening prose must not change
  documented behavior, command syntax, or code blocks. Don't touch fenced code.
- **Split by topic, not by line count.** A 600-line file flagged as bloat gets
  split where its sections naturally divide — then cross-link them.
- **Match the surrounding doc's voice** and formatting conventions.

## Gotchas

- The duplication detector only flags prose lines ≥40 chars; it deliberately
  skips headings, list bullets, and table rows (those repeat legitimately).
- Code inside ``` fences is ignored for fluff/dup/link/marker checks — so a
  `# comment` or a `TODO` in an example won't false-positive.
- "0 findings / exit 0" means the *mechanical* checks passed — not that the
  docs are well-written. Still read them; refactor what reading reveals.
- `--json` paths are relative to the cwd you ran from; run from the repo root
  for stable paths.

## Files

- `audit.mjs` — the audit driver (Node ≥18, zero dependencies).
- `principles.md` — the agent-harness doc principles to align docs toward.
