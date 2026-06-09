---
name: skill-creator
description: "Create or improve compact, research-backed SKILL.md files for agent use."
risk: low
source: user-requirements
created: "2026-06-03"
---

# Skill Creator

Use when creating or improving an agent skill file.

## Goal

Build SKILL.md for the agent reading it during work: compact, actionable, researched, no filler.

## Workflow

1. Read the existing skill if present.
2. Research official docs first. Use Context7 when available.
3. Download or save useful docs to a temporary location when doing deep research.
4. Review community knowledge when useful, especially Stack Overflow and prominent Reddit discussions.
5. Extract only durable, high-signal rules, traps, examples, and validation commands.
6. Write or edit SKILL.md.
7. Re-read it as the future agent user.
8. Remove repetition, long sentences, weak advice, and decorative text.
9. Iterate until the file is concise and complete enough for effective use.
10. Ask the user if scope, target audience, or tradeoffs are unclear.

## Format rules

- Keep it clean, compact, and checklist-oriented.
- Use headings that match implementation needs.
- Prefer bullets and small examples over long prose.
- Put the most important operational rules near the top.
- Avoid unnecessary source lists; summarize sources briefly.
- Avoid broad generic advice unless it changes implementation behavior.
- No emoji or decorative Unicode. Prefer ASCII only.
- Avoid special symbols when plain words work.
- No duplicated concepts in multiple sections unless needed for safety.
- Keep line length readable; shorten long sentences.

## Content rules

- Include critical pitfalls and exact fixes.
- Include short templates only when they prevent common mistakes.
- Include validation commands when relevant.
- Include version or environment caveats when behavior differs.
- Include community-discovered edge cases only if they are actionable.
- Prefer stable official docs over blog posts when they conflict.

## Self-review checklist

- Would this help me implement correctly without searching again?
- Is every bullet actionable?
- Is anything repeated?
- Can any sentence be shorter without losing meaning?
- Are examples minimal but complete?
- Is the skill free of emoji and non-ASCII text?
- Did I validate the file after editing?
