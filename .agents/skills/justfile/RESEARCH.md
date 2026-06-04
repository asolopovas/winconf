# Justfile Research

## Sources reviewed

- Just Programmer's Manual introduction: https://just.systems/man/en/
- Quick start: https://just.systems/man/en/quick-start.html
- Settings: https://just.systems/man/en/settings.html
- Recipe parameters: https://just.systems/man/en/recipe-parameters.html
- Dependencies: https://just.systems/man/en/dependencies.html
- Shebang recipes: https://just.systems/man/en/shebang-recipes.html
- Script recipes: https://just.systems/man/en/script-recipes.html
- Strings: https://just.systems/man/en/strings.html
- Attributes: https://just.systems/man/en/attributes.html
- Modules: https://just.systems/man/en/modules.html
- Command-line options: https://just.systems/man/en/command-line-options.html
- Avoiding argument splitting: https://just.systems/man/en/avoiding-argument-splitting.html
- Official repository and grammar: https://github.com/casey/just
- Community best-practice writeups found during search, used only for general validation against the official manual.

## What just is

`just` is a command runner. It stores project commands as recipes in `justfile`, `Justfile`, `.justfile`, or related module files. It is intentionally not a build system: recipes do not correspond to files, there is no need for `.PHONY`, and commands run because the user invokes them or because another recipe depends on them. `just` searches from the invocation directory upward for a justfile, then normally runs recipes with the working directory set to the directory containing that justfile.

Use justfiles to make common commands discoverable, reproducible, parameterized, and shell-friendly. Favor recipes for test, lint, build, format, serve, deploy, setup, cleanup, and project-specific maintenance tasks.

## Core syntax

A recipe has a name, optional parameters, optional dependencies, and an indented body.

```just
build target:
  cargo build --target '{{target}}'
```

Use `@` before a recipe or recipe line to suppress command echoing.

```just
@list:
  just --list

status:
  @git status --short
```

Assignments use `:=`.

```just
profile := 'dev'

run:
  ./app --profile '{{profile}}'
```

Recipe body interpolation uses `{{expression}}`. Interpolation is textual, so shell quoting is still required.

## Parameters

Parameters are declared after the recipe name.

```just
test filter:
  cargo test '{{filter}}'
```

Defaults are supported.

```just
test filter='':
  cargo test '{{filter}}'
```

Expressions in defaults are supported. Defaults containing `+`, `&&`, `||`, or `/` need parentheses.

```just
arch := 'wasm'

test triple=(arch + '-unknown-unknown') input=(arch / 'input.dat'):
  ./test '{{triple}}' '{{input}}'
```

The final parameter can be variadic. `+args` requires one or more values. `*args` accepts zero or more.

```just
fmt +files:
  prettier --write {{files}}

commit message *flags:
  git commit {{flags}} -m '{{message}}'
```

Dependency parameters are passed with parenthesized dependencies.

```just
build target:
  cargo build --target '{{target}}'

push target: (build target)
  ./scripts/push '{{target}}'
```

Parameters prefixed with `$` are exported to the shell environment.

```just
run $profile:
  ./app --profile "$profile"
```

Recent just versions support option-style recipe parameters with `[arg]` attributes.

```just
[arg('env', long='env', short='e', help='target environment')]
[arg('force', long='force', value='true')]
deploy env force='false':
  ./deploy --env '{{env}}' --force '{{force}}'
```

## Avoiding argument splitting

`{{param}}` is substituted before the shell parses the command. Without quotes, a single value containing spaces can become multiple shell arguments.

Unsafe:

```just
open path:
  xdg-open {{path}}
```

Safer with shell quoting:

```just
open path:
  xdg-open '{{path}}'
```

Best for arbitrary user strings is exported or positional arguments with double quotes.

```just
open $path:
  xdg-open "$path"
```

```just
[positional-arguments]
open path:
  xdg-open "$1"
```

For variadic parameters, intentional splitting is often desired. Avoid blindly quoting `{{files}}` if it should expand to many arguments.

## Dependencies

Dependencies run before the dependent recipe.

```just
test: build
  cargo test

build:
  cargo build
```

Within one `just` invocation, the same recipe with the same arguments runs only once, even if depended on multiple times.

Subsequent dependencies run after a recipe and are introduced with `&&`.

```just
package: build && checksum
  tar czf app.tar.gz target/release/app

checksum:
  sha256sum app.tar.gz
```

To run another recipe in the middle of a recipe, call `just recipe` recursively, but understand it is a separate invocation: variables may be recalculated, dependencies may run again, and command-line arguments are not automatically propagated.

## Settings

Settings control parsing and execution and should be placed near the top for readability.

Common settings:

```just
set dotenv-load
set shell := ['bash', '-uc']
set export
```

Important settings:

| Setting | Purpose |
|---|---|
| `dotenv-load` | Load `.env` if present |
| `dotenv-required` | Error if `.env` is missing |
| `dotenv-filename` | Search for a custom env filename in current and ancestor directories |
| `dotenv-path` | Load a specific env path and error if missing |
| `dotenv-override` | Let dotenv values override existing environment variables |
| `export` | Export all just variables to recipe environments |
| `fallback` | If a recipe is not found, search parent justfiles |
| `ignore-comments` | Ignore recipe lines beginning with `#` |
| `lazy` | Skip evaluating unused variables |
| `no-cd` | Do not change to the justfile directory |
| `positional-arguments` | Pass recipe args as shell positional args |
| `quiet` | Disable echoing commands by default |
| `script-interpreter` | Interpreter for empty `[script]` recipes, default `sh -eu` |
| `shell` | Shell for linewise recipes and backticks |
| `windows-shell` | Shell for Windows |
| `working-directory` | Working directory for recipes and backticks |

The default shell on Unix-like systems is effectively `sh -cu`. Many teams choose `bash -uc` for arrays and stricter unset-variable behavior, but `bash -euo pipefail` needs careful handling because just runs linewise recipes one line at a time unless using script or shebang recipes.

Dotenv values are environment variables, not just variables. Use `$NAME` in recipes and backticks, not `{{NAME}}`, unless you assign a just variable explicitly.

## Shells, scripts, and shebang recipes

Linewise recipes execute each line through the configured shell. State does not reliably persist across lines unless joined in one shell command or written as a script recipe.

Use script recipes for multi-line shell logic.

```just
[script]
check:
  set -eu
  cargo fmt --check
  cargo test
```

Use `[script(COMMAND)]` for explicit interpreters.

```just
[script('python3')]
hello:
  print('hello')
```

Use shebang recipes for different languages.

```just
report:
  #!/usr/bin/env python3
  print('report')
```

When shebang arguments are needed on Unix, `env -S` can split them portably enough for common systems.

```just
trace:
  #!/usr/bin/env -S bash -x
  echo hi
```

Script recipes avoid some shebang portability problems and use `set script-interpreter`, not `set shell`, when `[script]` has no command.

## Strings and expressions

String literals can be single-quoted, double-quoted, or triple-quoted. Double-quoted strings process escapes. Single-quoted strings do not.

```just
plain := 'a\tb'
escaped := "a\tb"
block := '''
  line one
  line two
'''
```

Normal strings do not support `{{}}` interpolation. Format strings do.

```just
name := 'world'
message := f'hello {{name}}'
```

Shell-expanded strings use `x'...'` and expand environment variables and leading `~` at compile time. They cannot use dotenv values loaded by just.

```just
cache := x'~/.cache/my-tool'
```

Built-in functions include path helpers, environment helpers, invocation and justfile directory helpers, and `shell(command, args...)`. Prefer path helpers over manually assuming invocation directories when writing reusable recipes.

Commonly useful functions include `justfile()`, `justfile_directory()`, `invocation_directory()`, `env_var()`, `env_var_or_default()`, `home_directory()`, path-joining with `/`, string transforms, and `shell()` for captured command output.

## Attributes

Attributes annotate recipes, aliases, and modules.

High-value attributes:

| Attribute | Use |
|---|---|
| `[default]` | Choose what `just` runs with no recipe |
| `[doc('text')]` | Set help/list documentation |
| `[group('name')]` | Group `--list` output |
| `[private]` | Hide helper recipes from normal list output |
| `[confirm]` | Prompt before dangerous recipes |
| `[confirm('prompt')]` | Custom confirmation prompt |
| `[linux]`, `[macos]`, `[windows]`, `[unix]` | Platform-specific recipes |
| `[no-cd]` | Run relative to invocation directory |
| `[working-directory('path')]` | Run in a specific directory |
| `[parallel]` | Run dependencies in parallel |
| `[positional-arguments]` | Use `$1`, `$2`, `$@` for this recipe |
| `[script]`, `[script('cmd')]` | Execute body as a script |
| `[env('NAME', 'VALUE')]` | Add an environment variable for one recipe |
| `[arg(...)]` | Add option, flag, help, or regex validation for parameters |

Dangerous or destructive recipes should use `[confirm]` and ideally expose a required `--force` flag with an `[arg(..., value=...)]` pattern.

## Modules and imports

Modules organize larger command surfaces.

```just
mod db
mod deploy 'tasks/deploy.just'
mod? local
```

A module named `foo` searches `foo.just`, `foo/mod.just`, `foo/justfile`, and `foo/.justfile`. Recipes in modules run as subcommands, such as `just db migrate` or `just db::migrate`.

Modules have separate variables, aliases, settings, and recipe namespaces. Recipes, aliases, and variables in one submodule are not available in another. Environment variables from parent modules are visible to child modules. Each module can load its own env files according to its settings.

Submodule recipes normally run with the working directory set to the directory containing the module source. `justfile()` and `justfile_directory()` still point at the root justfile.

Use modules when a justfile becomes large, when commands map to distinct domains, or when optional local overrides are useful. Use `mod? local` for developer-local recipes that should not break teammates if the file is absent.

## CLI commands useful to agents

| Command | Purpose |
|---|---|
| `just --list` | List public recipes |
| `just --summary` | Compact recipe names |
| `just --show recipe` | Show one recipe |
| `just --evaluate` | Evaluate assignments |
| `just --dump` | Print parsed justfile |
| `just --dump --dump-format json` | Machine-readable metadata |
| `just --dump >/dev/null` | Validate parse without running recipes |
| `just --fmt --check` | Check formatting |
| `just --fmt` | Format justfile |
| `just --choose` | Choose a recipe interactively if supported by the installed binary |
| `just --usage recipe` | Show usage for a recipe with options and argument docs |
| `just --yes recipe` | Auto-confirm `[confirm]` recipes, only when explicitly approved |

Always prefer `just --dump >/dev/null` before running recipes after edits. Use `just --list` and `just --show` to inspect a project before changing recipes.

## Best practices

- Put settings and shared variables at the top.
- Make `just` with no args helpful with `[default]` or a short list recipe.
- Keep recipe names verb-oriented and predictable: `test`, `lint`, `fmt`, `build`, `serve`, `clean`, `deploy`.
- Use `[group]` and `[doc]` comments or doc attributes for large command surfaces.
- Hide helpers with leading `_` or `[private]`.
- Use dependencies for setup that should run once per invocation.
- Use script recipes for multi-line logic, traps, loops, and strict shell behavior.
- Quote interpolations unless intentional shell splitting is desired.
- Use exported parameters or positional arguments for arbitrary strings and paths.
- Keep destructive recipes behind `[confirm]` and explicit flags.
- Prefer `dotenv-load` for local development, but do not rely on `.env` values being just variables.
- Avoid secrets in justfiles. Load secrets from environment or ignored dotenv files.
- Use platform attributes instead of ad hoc `uname` branches when commands differ entirely by OS.
- Use modules when a justfile grows too large.
- Validate parse with `just --dump >/dev/null` and formatting with `just --fmt --check` if available.

## Pitfalls

- `{{param}}` is not shell-quoted. Values containing spaces, quotes, glob characters, or shell metacharacters can break or become unsafe.
- Linewise recipes are not scripts. Shell state like `cd`, variables, and traps may not persist how authors expect across lines.
- Dotenv variables are environment variables. `{{DATABASE_URL}}` will fail unless `DATABASE_URL` is assigned as a just variable.
- `set export` can cause expensive variables to evaluate even when unused, especially with backticks.
- Recursive `just` calls are separate invocations and can rerun dependencies.
- Modules do not share variables or recipes with each other.
- `set windows-powershell` is deprecated. Use `set windows-shell`.
- Shebang argument splitting differs by OS. Prefer `[script(COMMAND)]` when portability matters.
- `--yes` bypasses confirmations and should not be used unless the user explicitly approves the destructive action.
- `just --fmt` rewrites formatting. Do not run it when preserving style is more important than canonical formatting.

## Compact template

```just
set dotenv-load
set shell := ['bash', '-uc']

[default]
[group('help')]
@list:
  just --list

[group('quality')]
fmt:
  cargo fmt

[group('quality')]
test filter='':
  cargo test '{{filter}}'

[private]
[script]
_ci:
  set -eu
  just fmt
  just test

[confirm('Deploy to production?')]
[arg('force', long='force', value='true', help='required confirmation flag')]
deploy force='false': test
  ./scripts/deploy --force '{{force}}'
```
