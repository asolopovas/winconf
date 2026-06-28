# Docs Architecture Template

Create or repair the docs tree to this shape before deep prose cleanup.

## Required tree

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

Keep this shape even when a repo is small. If a topic is not applicable, create
a short file that says so and points to the nearest source of truth.

## File roles

- `AGENTS.md`: agent rules, workflow, commands, source map, boundaries.
- `ARCHITECTURE.md`: system map, modules, data flow, integrations, risks.
- `docs/design-docs/index.md`: design doc map, status, owner, links.
- `docs/design-docs/core-beliefs.md`: product and engineering principles.
- `docs/exec-plans/active/`: current implementation plans.
- `docs/exec-plans/completed/`: finished plans and validation evidence.
- `docs/exec-plans/tech-debt-tracker.md`: accepted debt, owner, trigger, status.
- `docs/generated/`: generated docs with source and regeneration command.
- `docs/product-specs/index.md`: product spec map.
- `docs/product-specs/new-user-onboarding.md`: onboarding flow spec when relevant.
- `docs/references/`: copied external references for offline agent use.
- `docs/DESIGN.md`: UX, design system, interaction rules.
- `docs/FRONTEND.md`: frontend architecture, state, routing, build, UI tests.
- `docs/PLANS.md`: roadmap summary and links to exec plans.
- `docs/PRODUCT_SENSE.md`: users, jobs, tradeoffs, non-goals.
- `docs/QUALITY_SCORE.md`: quality bar, scorecard, no-comments gate, risks.
- `docs/RELIABILITY.md`: SLOs, failure modes, runbooks, recovery.
- `docs/SECURITY.md`: threat model, secrets, auth, data handling, checks.

## Minimal page template

Use these headings:

- Title as the single H1.
- Purpose: what this file owns.
- Source of truth: canonical files, commands, generated sources, or owners.
- Current state: facts that are true now.
- Validation: commands or checks that prove the doc is current.
- Links: related docs only, no repeated prose.

## Exec plan template

Use these headings:

- Plan name as the single H1.
- Goal.
- Scope.
- Acceptance criteria.
- Progress.
- Decisions.
- Validation.
- Debt.
