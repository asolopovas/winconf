#!/usr/bin/env node
// docs-refactor audit: mechanical pre-pass for a docs cleanup.
// Surfaces the tedious findings (fluff, duplication, broken links, bloat,
// structure issues) so the agent spends its budget on judgment, not grep.
//
// Usage:  node audit.mjs [dir ...] [--json] [--max-lines=N] [--top=N]
// Default dir: cwd. Scans *.md / *.mdx recursively, skips node_modules/.git.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, extname, dirname, resolve } from "node:path";

const args = process.argv.slice(2);
const flags = Object.fromEntries(
  args.filter((a) => a.startsWith("--")).map((a) => {
    const [k, v] = a.slice(2).split("=");
    return [k, v ?? true];
  })
);
const roots = args.filter((a) => !a.startsWith("--"));
if (roots.length === 0) roots.push(".");
const MAX_LINES = Number(flags["max-lines"] ?? 400);
const TOP = Number(flags["top"] ?? 12);
const SKIP = new Set(["node_modules", ".git", ".next", "dist", "build", "vendor"]);

// Filler / weasel words & phrases that almost always mark fluff in docs.
const FLUFF = [
  /\bin order to\b/gi, /\bit (is|'s) (important|worth|good) to (note|mention|remember)\b/gi,
  /\bplease note\b/gi, /\bas (mentioned|stated|noted) (above|below|earlier|previously)\b/gi,
  /\bneedless to say\b/gi, /\bat the end of the day\b/gi, /\bbasically\b/gi,
  /\bsimply\b/gi, /\bjust\b/gi, /\bvery\b/gi, /\breally\b/gi, /\bactually\b/gi,
  /\bquite\b/gi, /\bobviously\b/gi, /\bof course\b/gi, /\bessentially\b/gi,
  /\butiliz(e|es|ing|ation)\b/gi, /\bleverag(e|es|ing)\b/gi, /\bin terms of\b/gi,
  /\bthat being said\b/gi, /\bfor all intents and purposes\b/gi,
  /\bvarious\b/gi, /\bnumerous\b/gi, /\ba (wide )?(variety|number) of\b/gi,
];

function walk(dir, out = []) {
  let entries;
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const e of entries) {
    if (e.name.startsWith(".") && e.name !== ".") {
      if (SKIP.has(e.name)) continue;
    }
    if (SKIP.has(e.name)) continue;
    const p = join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if ([".md", ".mdx"].includes(extname(e.name).toLowerCase())) out.push(p);
  }
  return out;
}

const files = roots.flatMap((r) => walk(r));
const cwd = process.cwd();
const rel = (p) => relative(cwd, p).replace(/\\/g, "/");

const report = {
  scanned: files.length,
  bloat: [],        // oversized files
  fluff: [],        // high filler density
  duplication: [],  // lines repeated across/within files
  brokenLinks: [],  // local md links that don't resolve
  structure: [],    // heading problems
  staleMarkers: [], // TODO/FIXME/dated
  totals: { lines: 0, words: 0 },
};

const lineIndex = new Map(); // normalized line -> [{file, ln}]

for (const f of files) {
  let text;
  try { text = readFileSync(f, "utf8"); } catch { continue; }
  const lines = text.split(/\r?\n/);
  const words = text.split(/\s+/).filter(Boolean).length;
  report.totals.lines += lines.length;
  report.totals.words += words;

  // bloat
  if (lines.length > MAX_LINES)
    report.bloat.push({ file: rel(f), lines: lines.length, words });

  // Build a "prose" view: drop fenced code blocks and inline `code` spans so
  // docs that *document* linters (showing `TODO` or `[x](y.md)` as examples)
  // don't false-positive. Used by fluff/link/marker/dup checks.
  const stripInline = (s) => s.replace(/`[^`\n]+`/g, " ");
  let fenced = false;
  const prose = lines.map((l) => {
    if (/^\s*```/.test(l)) { fenced = !fenced; return ""; }
    return fenced ? "" : stripInline(l);
  });
  const proseText = prose.join("\n");

  // fluff density
  let hits = 0;
  const samples = [];
  for (const re of FLUFF) {
    const m = proseText.match(re);
    if (m) { hits += m.length; if (samples.length < 4) samples.push(m[0].toLowerCase()); }
  }
  const per100 = words ? +((hits / words) * 100).toFixed(2) : 0;
  if (hits >= 5 || per100 >= 1.5)
    report.fluff.push({ file: rel(f), hits, per100w: per100, samples: [...new Set(samples)] });

  // structure: headings
  const h1 = lines.filter((l) => /^#\s/.test(l));
  const headings = lines.filter((l) => /^#{1,6}\s/.test(l));
  if (h1.length === 0 && headings.length > 0)
    report.structure.push({ file: rel(f), issue: "no H1 (top-level) heading" });
  if (h1.length > 1)
    report.structure.push({ file: rel(f), issue: `${h1.length} H1 headings (split file?)` });
  // heading level jumps (e.g. ## -> ####)
  let prev = 0;
  for (const l of headings) {
    const lvl = l.match(/^#+/)[0].length;
    if (prev && lvl - prev >= 2) {
      report.structure.push({ file: rel(f), issue: `heading jump H${prev}->H${lvl}` });
      break;
    }
    prev = lvl;
  }

  prose.forEach((line, i) => {
    if (!line) return; // fenced or blank
    const ln = i + 1;

    // dup detection: meaningful prose/structural lines only
    const norm = line.trim().toLowerCase().replace(/\s+/g, " ");
    if (norm.length >= 40 && !/^[#>|*\-\d.]/.test(norm)) {
      if (!lineIndex.has(norm)) lineIndex.set(norm, []);
      lineIndex.get(norm).push({ file: rel(f), ln });
    }

    // broken local md links
    for (const m of line.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
      let target = m[1].split("#")[0].trim();
      if (!target || /^(https?:|mailto:|#|tel:)/.test(target)) continue;
      const abs = resolve(dirname(f), target);
      try { statSync(abs); } catch {
        report.brokenLinks.push({ file: rel(f), ln, target: m[1] });
      }
    }

    // stale markers
    const mark = line.match(/\b(TODO|FIXME|XXX|HACK|DEPRECATED)\b/);
    if (mark) report.staleMarkers.push({ file: rel(f), ln, marker: mark[1], text: line.trim().slice(0, 80) });
    const date = line.match(/\b(20[01]\d|2020|2021|2022|2023)-\d{2}-\d{2}\b/);
    if (date) report.staleMarkers.push({ file: rel(f), ln, marker: "old-date", text: line.trim().slice(0, 80) });
  });
}

// collate duplicates (same normalized line in 2+ places)
for (const [norm, locs] of lineIndex) {
  if (locs.length >= 2)
    report.duplication.push({ count: locs.length, text: norm.slice(0, 70), locs: locs.slice(0, 6) });
}
report.duplication.sort((a, b) => b.count - a.count);
report.bloat.sort((a, b) => b.lines - a.lines);
report.fluff.sort((a, b) => b.hits - a.hits);

if (flags.json) {
  console.log(JSON.stringify(report, null, 2));
  process.exit(0);
}

// ---- human-readable, prioritized ----
const trunc = (arr, n = TOP) => arr.slice(0, n);
const bar = "─".repeat(60);
console.log(`\nDOCS AUDIT  ·  ${report.scanned} files  ·  ${report.totals.lines} lines  ·  ${report.totals.words} words`);
console.log(bar);

function section(title, items, fmt) {
  console.log(`\n## ${title}  (${items.length})`);
  if (items.length === 0) { console.log("  none"); return; }
  for (const it of trunc(items)) console.log("  " + fmt(it));
  if (items.length > TOP) console.log(`  … and ${items.length - TOP} more (use --json for all)`);
}

section("BLOAT — split or trim", report.bloat, (b) => `${b.lines}L ${b.words}w  ${b.file}`);
section("FLUFF — tighten prose", report.fluff, (f) => `${f.hits} hits (${f.per100w}/100w)  ${f.file}  [${f.samples.join(", ")}]`);
section("DUPLICATION — consolidate", report.duplication, (d) => `x${d.count}  "${d.text}"  → ${d.locs.map((l) => `${l.file}:${l.ln}`).join(", ")}`);
section("BROKEN LINKS — fix or drop", report.brokenLinks, (l) => `${l.file}:${l.ln}  → ${l.target}`);
section("STRUCTURE — heading hygiene", report.structure, (s) => `${s.file}  — ${s.issue}`);
section("STALE MARKERS — review", report.staleMarkers, (s) => `${s.file}:${s.ln}  [${s.marker}] ${s.text}`);

const findings = report.bloat.length + report.fluff.length + report.duplication.length +
  report.brokenLinks.length + report.structure.length + report.staleMarkers.length;
console.log(`\n${bar}\nTOTAL ${findings} findings. Fix broken links first, then dedup, then trim bloat/fluff.\n`);
process.exit(findings > 0 ? 1 : 0);
