---
name: justfile
description: Use for creating, reading, editing, and validating justfiles, Justfile/.justfile files, *.just modules, and just recipes.
---

# Justfile

## Workflow

- Inspect: `just --list`, `just --summary`, `just --show <recipe>`, `just --dump`, `just --evaluate`.
- Validate parse: `just --dump >/dev/null`. Check format: `just --fmt --check`; run `just --fmt` only when wanted.
- Run targeted recipes only. Ask before deploy, destructive, sudo, Docker, UI, or `just --yes`.

## Essentials

```just
set dotenv-load
set shell := ['bash', '-uc']

[default]
@list:
  just --list

test filter='':
  cargo test '{{filter}}'
```

- Recipes are commands, not files; no `.PHONY`. Default run is `[default]` or first recipe.
- Recipes run from the justfile dir; use `[no-cd]` for invocation cwd.
- Linewise lines are separate shell invocations. Use `[script]` or `#!` for one script.
- Assign `name := expr`; interpolate `{{expr}}`; literal `{{` is `{{{{`.
- Backticks or `shell()` capture command output during evaluation.
- Params: `arg='default'`, `+rest` one-or-more, `*rest` zero-or-more.
- Dependency args: `(task arg)`; after-deps: `&&`.
- Override vars: `just name=value task` or `just --set name value task`.
- Dotenv and `$param` are env vars; use `$NAME`, not `{{NAME}}`.
- `{{arg}}` is raw text. Use `'{{arg}}'`; for arbitrary paths/text prefer `$path` with `"$path"` or `[positional-arguments]` with `"$@"`.
- Prefixes: `@` hides echo, `-` ignores failure. Helpers: `_name` or `[private]`; aliases: `alias t := test`.
- Attributes: `[default]`, `[confirm]`, `[group]`, `[private]`, `[script]`, `[no-cd]`, `[working-directory(...)]`, `[linux|macos|windows]`, `[arg(...)]`.
- Organize with `import? 'local.just'`, `mod db`, `mod? local`; modules have isolated vars, recipes, aliases, and settings.
