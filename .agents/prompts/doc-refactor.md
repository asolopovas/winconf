---
description: Refactor Docs
---

# Task

Refactor my docs to be as concise as possible, removing repetition and fluff while aligning them with the following article.

# Agent Harness: Implementation Essentials

## Goal

Enable agents to implement, validate, review, and maintain software safely. Humans provide intent, constraints, acceptance criteria, and judgment. Agents execute inside a mechanically enforced harness.

## 1. Repository Knowledge System

Treat the repository as the source of truth. Knowledge outside the repo is invisible to agents until encoded as markdown, code, schemas, generated docs, or execution plans.

Use `AGENTS.md` as a short map, not a manual. It should point agents to deeper sources of truth.

Recommended layout:

```text
AGENTS.md
ARCHITECTURE.md
docs/
  design-docs/
  exec-plans/
    active/
    completed/
    tech-debt-tracker.md
  generated/
  product-specs/
  references/
  DESIGN.md
  FRONTEND.md
  QUALITY.md
  RELIABILITY.md
  SECURITY.md
scripts/
tests/
```

CI should validate documentation structure, cross-links, generated artifact freshness, and stale or obsolete docs.

## 2. Planning and Task Loop

Use lightweight plans for small work and checked-in execution plans for complex work.

Execution plans should include:

- Goal
- Scope
- Acceptance criteria
- Progress log
- Decisions made
- Validation performed
- Follow-up debt

Standard agent loop:

```text
Prompt -> inspect repo -> plan -> implement -> run checks -> drive app -> inspect logs/metrics/traces -> self-review -> open PR -> respond to feedback -> rerun checks -> merge or escalate
```

## 3. Isolated Worktree Runtime

Each task should run in an isolated git worktree with its own app instance and disposable local services.

Required capabilities:

- Isolated environment variables, ports, databases, caches, logs, metrics, and traces
- Per-worktree app startup and teardown
- No cross-task state leakage
- Repeatable local setup and cleanup scripts

## 4. App Validation Harness

Agents must be able to operate the running app directly through Chrome DevTools Protocol, Playwright, or an equivalent browser-control interface.

Required validation sequence:

1. Select target and clear console.
2. Capture a before snapshot.
3. Trigger the UI path.
4. Observe runtime events during interaction.
5. Capture an after snapshot.
6. Apply fix and restart.
7. Re-run validation until clean.

Required tooling:

- DOM snapshots
- Screenshots
- Navigation and form interaction
- Console and runtime event capture
- Video or trace capture for bugs and fixes
- Repeatable user journey scripts

## 5. Local Observability Harness

Expose logs, metrics, and traces to agents in local development.

Recommended topology:

```text
App -> Vector -> VictoriaLogs / VictoriaMetrics / VictoriaTraces
```

Expose query APIs:

- Logs through LogQL
- Metrics through PromQL
- Traces through TraceQL

Agents should query, correlate, and reason over observability data, then implement fixes, restart the app, rerun workloads, retest UI journeys, and repeat.

Acceptance criteria can include startup time, latency limits, span duration limits, absence of specific errors, and no reliability regressions.

## 6. Mechanical Architecture Enforcement

Architecture rules must be enforced by custom lints, structural tests, and CI.

Allowed domain edges:

```text
Types -> Config -> Repo -> Service -> Runtime -> UI
Providers -> Service
Providers -> App Wiring + UI
Runtime -> App Wiring + UI
Utils -> Providers
```

Rules:

- Cross-cutting concerns such as auth, connectors, telemetry, and feature flags enter only through `Providers`.
- External data is parsed at system boundaries.
- Schemas, contracts, and types are explicit.
- Forbidden imports and reverse dependencies fail checks.
- Structured logging, naming conventions, file size limits, and platform reliability rules are enforced.
- Lint errors include remediation instructions for agents.

## 7. Testing and CI

Agents must be able to run the same checks locally and in CI.

Minimum checks:

- Formatting
- Type checks
- Unit tests
- Integration tests
- End-to-end user journeys
- Dependency boundary checks
- Documentation structure checks
- Generated artifact freshness checks
- Observability or performance assertions where relevant

## 8. Pull Requests and Review

Prefer small, short-lived pull requests.

Each pull request should include:

- Clear summary
- Acceptance criteria addressed
- Validation commands and results
- Screenshots, videos, traces, or logs for UI and runtime changes
- Known follow-ups

Agents should self-review, request additional agent reviews, respond to feedback, rerun checks, and escalate only when human judgment is required.

## 9. Continuous Cleanup

Agents copy existing patterns, including bad ones. Prevent drift with recurring cleanup tasks.

Cleanup loop:

- Encode golden principles as docs, examples, tests, or lints
- Scan for violations
- Update quality grades by domain or layer
- Open targeted refactor PRs
- Automerge low-risk cleanup after checks pass
- Promote repeated review feedback into mechanical enforcement

## 10. Best Practices

- Keep instructions short and linked.
- Prefer stable, composable technology with clear APIs.
- Make hidden knowledge visible in the repo.
- Enforce invariants mechanically instead of relying on reminders.
- Make the app and runtime observable, controllable, and restartable by agents.
- Capture human taste as reusable examples, docs, tests, or lints.
- Treat documentation freshness as a CI concern.
- Use agents to maintain the harness itself.
- Escalate only for judgment, product tradeoffs, risk, or ambiguity.

## Definition of a Good Harness

A good harness lets an agent independently understand context, modify code, validate behavior, inspect failures, update docs, pass checks, handle review, and preserve architecture without relying on hidden human knowledge.
