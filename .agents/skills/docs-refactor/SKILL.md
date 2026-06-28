---
name: docs-refactor
description: "Refactor and repair documentation trees: audit, trim, dedupe, fix links, create missing docs, and enforce the repository docs architecture template."
---

# docs-refactor

Use this skill for docs cleanup, docs audits, docs architecture updates, and
requests to make documentation compact and agent-ready.

## Non-negotiables

- Fix docs in the repo. Do not stop at advice.
- Create missing docs and directories from `architecture-template.md`.
- Keep `AGENTS.md` a short map: rules, workflow, commands, source links.
- Put durable facts in the canonical file. Replace repeats with links.
- Preserve command syntax, paths, options, code fences, and behavior.
- Treat docs as code: versioned markdown, reviewed with code, checked links,
  generated-doc commands, and decision records.
- Enforce the no-comments policy in code. Keep only comments that are functional
  syntax or toolchain directives and cannot be removed without changing build,
  typecheck, generation, or documentation output.

## Comment cleanup

Run `node <skill-dir>/audit.mjs . --comments --architecture` to find comments in
JavaScript, TypeScript, JSX, TSX, PHP, Go, and Rust.

Keep untouched only after verifying necessity:

- Shebangs.
- TypeScript triple-slash references.
- JSX pragma comments that alter compilation.
- Go build tags, `//go:` directives, cgo directives, and generated-code markers.
- Rust doc comments when rustdoc or `missing_docs` requires them.

Remove explanatory comments, LLM notes, section labels, stale task markers,
commented-out code, and lint-suppression comments. Prefer fixing code over
keeping suppressions.

Use language-aware removal, not regex:

- JS/TS/JSX/TSX: Babel parser and generator with `comments: false`, or
  `decomment` for quick cleanup.
- PHP: `PhpToken::tokenize` or `token_get_all`; remove `T_COMMENT` and
  `T_DOC_COMMENT`; validate with `php -l`.
- Go: `go/parser` and `go/printer` or an AST tool; preserve build and cgo
  directives; validate with `gofmt` and `go test ./...`.
- Rust: tree-sitter tools such as `uncomment` or `silence-cli`; preserve needed
  rustdoc comments; validate with `cargo fmt` and `cargo test`.

## Audit first

Run from the target repo root:

```bash
node <skill-dir>/audit.mjs docs
node <skill-dir>/audit.mjs . --architecture --comments
node <skill-dir>/audit.mjs . --json
node <skill-dir>/audit.mjs README.md docs --top=30
```

`<skill-dir>` is this skill directory. Flags: `--json`, `--max-lines=N`,
`--top=N`. Exit code `1` means findings exist.

Fix in this order:

1. Broken links.
2. Duplicate facts.
3. Missing architecture files and directories.
4. Nonfunctional code comments.
5. Bloat.
6. Fluff and hedging.
7. Heading structure.
8. Stale markers.

## Enforced architecture

Use `architecture-template.md`. The required shape is:

```text
AGENTS.md
ARCHITECTURE.md
docs/
├── design-docs/
│   ├── index.md
│   ├── core-beliefs.md
│   └── ...
├── exec-plans/
│   ├── active/
│   ├── completed/
│   └── tech-debt-tracker.md
├── generated/
│   └── db-schema.md
├── product-specs/
│   ├── index.md
│   ├── new-user-onboarding.md
│   └── ...
├── references/
│   ├── design-system-reference-llms.txt
│   ├── nixpacks-llms.txt
│   ├── uv-llms.txt
│   └── ...
├── DESIGN.md
├── FRONTEND.md
├── PLANS.md
├── PRODUCT_SENSE.md
├── QUALITY_SCORE.md
├── RELIABILITY.md
└── SECURITY.md
```

Create a required file even when the topic is not applicable. Keep it short:
state status, link the nearest source of truth, and note validation or owner.
Do not invent product, security, reliability, schema, or UX facts.

## Refactor loop

1. Audit and record counts.
2. Compare the repo to `architecture-template.md`.
3. Create or move docs into the required shape.
4. Read only files needed for the top findings.
5. Move each fact to its canonical file.
6. Replace repeated prose with links.
7. Split by topic, not by line count.
8. Delete filler, restatements, and obsolete notes.
9. Remove nonfunctional comments with language-aware tools.
10. Re-audit until clean or only intentional findings remain.
11. Report changed files, findings before/after, validation, and accepted debt.

## Page checks

For every changed file:

- One H1.
- No skipped heading levels.
- Local links resolve.
- No duplicated source-of-truth facts.
- No unresolved task markers or stale date.
- No code comments except verified functional directives.
- New docs are linked from `AGENTS.md`, `ARCHITECTURE.md`, or the nearest index.

## Files

- `audit.mjs`: zero-dependency Node 18+ docs audit.
- `principles.md`: compact doc principles.
- `architecture-template.md`: required docs tree and page templates.
