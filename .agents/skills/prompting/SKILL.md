---
name: prompting
description: "Improve prompts for Claude's latest models: clarity, examples, XML structure, output control, tool use, thinking, and agentic systems."
risk: low
source: anthropic-prompting-guide
created: "2026-06-09"
---

# Prompting

Use when writing or improving a prompt for Claude (Opus/Sonnet/Haiku 4.x). Apply only the sections that match the problem.

## Core rules

- Be explicit. Treat Claude as a capable new hire with no context. State output format, constraints, and scope directly.
- Golden test: if a colleague with minimal context would be confused by the prompt, so will Claude.
- Tell it what TO do, not what to avoid. "Write flowing prose paragraphs" beats "don't use lists".
- Give the reason behind an instruction. Claude generalizes from the why.
- State scope explicitly when an instruction should apply broadly ("apply to every section, not just the first"). Newer models follow instructions literally and won't infer reach.
- Want "above and beyond"? Ask for it. "Include as many relevant features as possible; go beyond the basics."
- Match prompt style to desired output (remove markdown from the prompt to reduce markdown in the output).

## Structure

- Wrap distinct content in descriptive XML tags: `<instructions>`, `<context>`, `<example>`, `<input>`. Reuse tag names consistently.
- Use a system prompt to set a role ("You are a Python coding assistant"). One sentence shifts tone and focus.
- Sequential steps that must all happen, or happen in order: use a numbered list.

## Examples (few-shot)

- 3-5 examples is the sweet spot. Strongest lever for format, tone, structure.
- Make them relevant (mirror the real task), diverse (cover edge cases, avoid accidental patterns), and wrapped in `<example>` tags (`<examples>` for a set).

## Long context (20k+ tokens)

- Put long documents at the TOP, above the query/instructions. Queries at the end can improve quality up to 30%.
- Wrap each doc: `<document index="n"><source>...</source><document_content>...</document_content></document>`.
- For long-doc tasks, ask Claude to first extract relevant quotes into `<quotes>` tags, then answer from them.

## Output control

- Format steering, in order of strength: explicit instruction -> XML tag indicators (`<prose>...</prose>`) -> match prompt style to output.
- Reduce markdown/bullets: instruct to write flowing prose, reserve markdown for code and headings, avoid bold/italics and reflexive lists.
- Plain-text math: forbid LaTeX/`$`/`\frac` explicitly and require text operators (`/`, `*`, `^`).
- Want summaries after tool calls? Ask for them; newer models often skip straight to the next action.
- Prefills on the final assistant turn are unsupported on 4.6+. Replace with Structured Outputs, tool calling, or "respond directly without preamble".

## Tool use

- To make Claude act, use imperatives ("Change this function") not suggestions ("Can you suggest changes") — the latter yields advice, not edits.
- Parallel calls: independent calls should fire together. Add a `<use_parallel_tool_calls>` note for ~100% rate; call dependent steps sequentially, never guess parameters.
- Don't over-prompt tool triggers. Newer models trigger appropriately; "CRITICAL: you MUST use X" causes overtriggering. Prefer "Use X when...".
- Action posture is steerable: add a `<default_to_action>` block to act by default, or `<do_not_act_before_instructions>` to research-and-recommend by default.

## Effort and thinking

- `effort` trades intelligence vs. speed/cost: `xhigh` for coding/agentic, min `high` for intelligence-sensitive, `medium`/`low` for latency or scoped work. Raise effort to fix shallow reasoning rather than prompting around it.
- Adaptive thinking (`thinking: {type: "adaptive"}`) lets Claude decide when/how much to think; off by default unless set. Use for agentic loops, multi-step tool use, complex coding.
- Too much thinking: lower effort, or add "respond directly when in doubt; only think for multi-step reasoning".
- Too little at low effort: add "this needs multi-step reasoning; think carefully before responding".
- `budget_tokens` is deprecated; control depth with `effort`, cap cost with `max_tokens`.
- When thinking is off, the word "think" is a strong trigger; use "consider/evaluate/reason through" to avoid waking it.
- Use `<thinking>` tags inside few-shot examples to demonstrate a reasoning style. Ask Claude to self-check against test criteria before finishing.

## Agentic systems

- Reduce overengineering: scope to what was asked; no extra files, abstractions, defensive code, or docs on untouched code.
- Generalize, don't game tests: "implement the actual logic for all valid inputs, not just test cases; do not hard-code; tell me if a test is wrong rather than working around it".
- Reduce hallucination: "never speculate about code you haven't opened; read referenced files before answering".
- Reduce scratch files: "clean up any temporary files you create at the end".
- Confirm risky actions: ask before destructive/irreversible/shared-system operations (rm -rf, force-push, dropping tables, posting externally); never bypass safety checks as a shortcut.
- Subagents: let Claude orchestrate; if overused, specify "use subagents for parallel/isolated/independent work; work directly for simple, sequential, single-file, or shared-context tasks".

### Multi-context-window / long-horizon

- Tell Claude context will compact so it doesn't wrap up early: "save progress and state to memory before the window refreshes; never stop a task early over token budget".
- First window sets up framework (tests, setup scripts); later windows iterate on a todo list.
- Track state: structured data (test status) as JSON; progress notes as freeform text; use git for checkpoints. "Do not remove or edit tests."
- Starting fresh can beat compaction — newer models reconstruct state from the filesystem. Be prescriptive: "run pwd; review progress.txt, tests.json, git log; run an integration test before new work."

## Frontend design

- Default house style (cream backgrounds, serif display, terracotta accent) fits editorial/hospitality but not dashboards/fintech/enterprise. Generic negatives ("don't use cream") just shift to another fixed palette.
- To break the default: (1) give a concrete spec (exact hex palette, typeface, radius, spacing), or (2) "propose 4 distinct visual directions, ask the user to pick, then build only that one".
- Anti-"AI slop" snippet: forbid Inter/Roboto/Arial/system fonts and purple-on-white gradients; require distinctive fonts, cohesive committed palette, and purposeful motion.

## Workflow when improving a prompt

1. Identify the failing behavior (verbosity, wrong format, no action, shallow reasoning, overengineering).
2. Pick the matching lever above. Prefer one targeted change at a time.
3. Prefer positive examples over negative instructions.
4. Measure the effect on real cases or evals before stacking more changes.
