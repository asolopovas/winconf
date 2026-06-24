---
name: rust-100k
description: Engineering practices for medium-to-large Rust projects (10k-200k+ LOC) from matklad's "One Hundred Thousand Lines of Rust" series. Use when structuring Cargo workspaces, cutting compile/CI times, organizing tests, applying #[inline], or writing ARCHITECTURE.md.
source: https://matklad.github.io/2021/09/05/Rust100k.html
---

# Rust at 100k Lines

Durable practices for medium-to-large Rust codebases. Apply when laying out a
workspace, fighting slow builds, designing tests, or deciding on `#[inline]`.
Most rules earn their keep only past ~10k LOC; for small crates, skip the
optimization and keep defaults.

## Workspace and crate layout

- Single workspace, flat crate list. Root is a virtual manifest with no code:
  ```toml
  # ./Cargo.toml
  [workspace]
  members = ["crates/*"]
  ```
  Putting the main crate in the root pollutes it with `src/` and forces
  `--workspace` on every command.
- Each crate lives in `crates/<name>/`; crate name == folder name exactly. No
  prefix stripping or abbreviation. Renames and navigation stay mechanical.
- Keep `src/lib.rs` even for a one-file crate; never drop `lib.rs` next to
  `Cargo.toml`. Crates grow.
- `version = "0.0.0"` for internal, unpublished crates.
- Crates meant for publishing go in a separate `libs/`; internal-only in `crates/`.
  The split also makes it easy to verify `libs/` never depends on `crates/`.
- Put all repo automation in a Rust `xtask` crate, not Makefiles or `*.sh`.
- Split crates to shape a DAG, not a chain. `A -> C -> E` (B, D as siblings of C)
  compiles in parallel; `A -> B -> C -> D -> E` serializes. The key property of a
  crate is which crates it does *not* depend on - that bounds incremental rebuilds.

## Fast builds (CI especially)

- Cache dependencies, not your own crates. Caching all of `./target` fails: it is
  huge and dominated by volatile local artifacts. Clean local crates from
  `./target` before saving the cache. On GitHub Actions use `Swatinem/rust-cache`.
- Disable debuginfo in CI - it makes `./target` much bigger, which hurts caching:
  ```toml
  [profile.dev]
  debug = 0
  ```
- Set these in the CI job env (not in source): kill incremental (near-full
  rebuilds gain nothing from it) and deny all warnings with one flag instead of
  per-crate `#![deny(warnings)]`, which would hurt local dev:
  ```yaml
  env:
    CARGO_INCREMENTAL: 0
    RUSTFLAGS: "-D warnings"
  ```
- Bump cargo network retry limits in CI to ride out flaky registry fetches.
- Baseline: a ~200k-line project tuned for build time runs CI in ~10 min on
  GitHub Actions. Far off that and there is low-hanging fruit.
- Split build vs test timing: `cargo test --no-run` then `cargo test`.
- Audit `Cargo.lock` (not `Cargo.toml`): for each dependency, does it solve a real
  problem here? Trim deps, disable unneeded features, or upstream a PR making a
  feature optional.
- Profile before cutting: `cargo +nightly build -Z timings --release` emits an
  HTML timeline of per-crate compile time and the critical path.
- Proc macros break pipelining: `rustc` must fully build the macro crate before
  dependents' metadata is known; `syn` punches CPU-idle holes. Enabling a derive
  feature (e.g. `serde` derive) on a shared crate forces *all* its reverse-deps to
  wait on `syn`. Use derives sparingly; push macro-heavy crates late in the DAG.
- Static linking is `m libs x n binaries` of link work. Each file in `examples/`
  and `tests/` is its own binary by default - consolidate. A busybox-style single
  binary dispatched on `argv[0]` cuts link artifacts.

## Monomorphization and #[inline]

`#[inline]` is about crate boundaries, not a generic "go faster" knob.

- Within a crate the compiler already inlines well; do not annotate private fns.
- Across crates a function body is invisible downstream and *cannot* inline unless
  marked `#[inline]` (which emits a copy per consuming codegen unit - costs compile
  time). Generic functions are implicitly inlinable because they compile in the
  caller's crate.
- Applying `#[inline]` everywhere worsens build times for little gain.
- Libraries: proactively `#[inline]` small, non-generic public fns, especially
  trivial trait impls (`Deref`, `AsRef`, etc.). `#[inline]` is NOT transitive - a
  public `#[inline]` fn calling a private one needs the private one annotated too.
- Applications: add `#[inline]` reactively after profiling. If you do not care
  about compile time, `lto = true` in the release profile is the better fix - it
  gets cross-crate inlining without scattering `#[inline]` or recompiling per crate.
- Split a rarely-taken slow path (lazy init, error formatting) into a `#[cold]` fn
  so the hot path stays small enough to inline well.
- Keep generics off crate boundaries to limit monomorphization bloat (each crate
  re-instantiates the same type params). Wrap a generic signature around a
  non-generic inner fn:
  ```rust
  pub fn read<P: AsRef<Path>>(path: P) -> io::Result<Vec<u8>> {
    fn inner(path: &Path) -> io::Result<Vec<u8>> {
      let mut file = File::open(path)?;
      let mut bytes = Vec::new();
      file.read_to_end(&mut bytes)?;
      Ok(bytes)
    }
    inner(path.as_ref())
  }
  ```
  Prefer `&dyn Fn()` over `impl Fn()` at boundaries for the same reason.
- Inspect bloat: `cargo llvm-lines --lib --release -p <crate> | head -n 20`.

## Testing

- Test observable behavior, not implementation. "Neural-network test": would the
  test still pass if the implementation were swapped for an opaque equivalent? If
  yes, it survives refactors.
- Pick the boundary deliberately: for a library it is the public API; for an
  application it is what a human sees on screen. Write tests at that boundary.
- Layered design -> test each layer through the one below it (`L1`; then `L1<-L2`;
  then `L1<-L2<-L3`). Upper-layer tests already exercise lower layers, and a change
  only recompiles its own layer.
- Route assertions through one `check` helper so an API change touches one place,
  not every test. Mark it `#[track_caller]` so failures point at the call site:
  ```rust
  #[track_caller]
  fn check(haystack: &[i32], needle: i32, expected: bool) {
    assert_eq!(binary_search(haystack, &needle), expected);
  }
  ```
- Sans-IO: keep logic pure and push IO to the edges. Code volume does not slow
  tests; IO does. In-memory pipelines run in milliseconds.
- Make adding a test trivial; friction compounds across a suite.
- Data-driven tests: express cases as data (text/JSON/DSL) processed by one runner.
  Enables serialization, reuse across languages, and tooling. Keep one tiny
  inline smoke test for per-test "Run" buttons / debugging.
- Snapshot/expect testing for large or churny output: crates `expect-test`,
  `insta`, `k9` rewrite the expected literal on an opt-in update run.
- Gate slow/IO tests with an env var, return early when unset - NOT `#[cfg]`,
  which hides them from the IDE:
  ```rust
  #[test]
  fn slow() {
    if std::env::var("RUN_SLOW_TESTS").is_err() { return; }
    // ...
  }
  ```
- Avoid heavy mocks and fluent-assertion libraries; use real subsystems (kept fast
  by sans-IO). Start with a bare `assert!`; add a detailed message the first time
  you actually debug its failure, not before.
- Coverage marks: to test that something does NOT happen (or that a branch fired
  for the right reason), have the code emit a mark/log and assert on it rather than
  exposing internals.
- Background work with no completion signal (`fn do_stuff_in_background(p)`) is
  fundamentally untestable - give it a way to await/observe completion (structured
  concurrency) so a test has a synchronization point.
- Collocate tests with code by default; print test times so IO outliers surface.
- Reuse the test harness for project hygiene: assert formatting, license headers,
  and performance regressions as ordinary `#[test]`s.
- Enforce the not-rocket-science rule (bors): only land commits green on main.
- Beyond examples, escalate to property tests, exhaustive small-input generation,
  and coverage-guided / structured fuzzing once tests are data-driven.

## Delete Cargo integration tests

Each file in `tests/` becomes its own binary: the lib is re-linked per file and
binaries run sequentially. Cargo's own cleanup here cut compile time ~3x and disk
~5x.

- Public-API library: keep ALL integration tests in ONE binary named `it`
  (i + t = integration test). Small crate -> a single `tests/it.rs`. Larger -> a
  module tree:
  ```
  tests/it/main.rs   # mod foo; mod bar;
  tests/it/foo.rs
  tests/it/bar.rs
  ```
- Internal library: skip integration tests; unit-test via a submodule, and pull
  it into a separate file so editing tests does not recompile the lib:
  ```rust
  // src/lib.rs
  #[cfg(test)]
  mod tests;   // lives in src/tests.rs
  ```
  Disable doctests (each links as a separate binary, very slow) for internal crates:
  ```toml
  [lib]
  doctest = false
  ```
- Extreme, for big workspaces (the pernosco approach): set `[lib] test = false`,
  make unit-tested APIs `pub`, and put every test in one workspace-level test
  crate. Also stops the lib being compiled twice (with and without `--test`).

## ARCHITECTURE.md

For projects ~10k-200k LOC. Closes the gap between new and core contributors:
new ones spend ~10x longer finding *where* to change code than *how*. It also
externalizes the maintainers' own mental map. Name the file `ARCHITECTURE`
(uppercase) in the repo root beside `README` and `CONTRIBUTING`; rust-analyzer's
is a good model.

- Open with a bird's-eye statement of the problem the project solves.
- Core is a codemap: coarse modules and how they relate. Answer "where is the thing
  that does X?" and "what does this thing do?". A map of the country, not an atlas.
- Name important files/modules/types but DO NOT link them (links rot) - readers use
  symbol search, which also surfaces siblings, and needs no upkeep.
- State invariants, especially as absences ("nothing in the model layer depends on
  the views"), and call out layer/system boundaries - both are invisible in code.
- Add a section for cross-cutting concerns.
- Keep it short (everyone reads it). No implementation details - pull those into
  separate docs or, better, inline documentation. Do not sync with code; revisit a
  couple times a year.

## Validation

```bash
cargo +nightly build -Z timings --release       # per-crate compile timeline
cargo llvm-lines --lib --release -p <crate>      # monomorphization bloat
cargo tree --duplicates                          # duplicate dep versions
```
