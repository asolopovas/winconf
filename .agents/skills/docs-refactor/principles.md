# Agent-Harness Doc Principles

The target docs should align to these. Distilled from "Agent Harness:
Implementation Essentials." Treat each as a test you apply while refactoring.

## Source of truth

- The **repo** is the source of truth. Knowledge outside it is invisible to
  agents until encoded as markdown, code, schemas, or generated docs.
- `AGENTS.md` is a short **map**, not a manual — it points to deeper sources.
- Recommended layout: `AGENTS.md`, `ARCHITECTURE.md`, and a `docs/` tree
  (`design-docs/`, `exec-plans/{active,completed}/`, `generated/`,
  `product-specs/`, `references/`, plus `DESIGN.md` / `QUALITY.md` /
  `RELIABILITY.md` / `SECURITY.md`).
- Treat doc freshness as a CI concern: validate structure, cross-links,
  generated-artifact freshness, and stale/obsolete pages.

## Writing standard

- **Short and linked** beats long and self-contained. Split monoliths; link.
- **One source of truth per fact.** No restating the same thing in two files.
- Make hidden knowledge visible in the repo; capture human taste as reusable
  examples, docs, tests, or lints.
- Enforce invariants **mechanically** (lints, structural tests, CI) instead of
  relying on prose reminders.

## What good docs let an agent do

Independently: understand context → modify code → validate behavior → inspect
failures → update docs → pass checks → handle review → preserve architecture —
without relying on hidden human knowledge.

## Refactor checklist (per file)

- [ ] Does it earn its length, or should it be split / merged / deleted?
- [ ] Any fact stated here that's already authoritative elsewhere? → link instead.
- [ ] Filler, hedging, restatement removed?
- [ ] Links resolve; one H1; heading levels don't skip.
- [ ] Points to deeper sources rather than duplicating them.
- [ ] Commands and code blocks preserved exactly.
