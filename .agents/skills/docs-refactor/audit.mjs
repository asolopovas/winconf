#!/usr/bin/env node
import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, extname, join, relative, resolve } from "node:path";

const args = process.argv.slice(2);
const flags = Object.fromEntries(
	args
		.filter((arg) => arg.startsWith("--"))
		.map((arg) => {
			const [key, value] = arg.slice(2).split("=");
			return [key, value ?? true];
		}),
);
const roots = args.filter((arg) => !arg.startsWith("--"));
if (roots.length === 0) roots.push(".");

const MAX_LINES = Number(flags["max-lines"] ?? 400);
const TOP = Number(flags.top ?? 12);
const CHECK_ARCHITECTURE = Boolean(flags.architecture);
const CHECK_COMMENTS = Boolean(flags.comments);
const SKIP = new Set([
	"node_modules",
	".git",
	".next",
	"dist",
	"build",
	"vendor",
]);
const DOC_EXTENSIONS = new Set([".md", ".mdx"]);
const COMMENT_EXTENSIONS = new Set([
	".js",
	".jsx",
	".ts",
	".tsx",
	".mjs",
	".cjs",
	".mts",
	".cts",
	".go",
	".php",
	".rs",
]);
const REQUIRED_ARCHITECTURE = [
	"AGENTS.md",
	"ARCHITECTURE.md",
	"docs",
	"docs/design-docs",
	"docs/design-docs/index.md",
	"docs/design-docs/core-beliefs.md",
	"docs/exec-plans",
	"docs/exec-plans/active",
	"docs/exec-plans/completed",
	"docs/exec-plans/tech-debt-tracker.md",
	"docs/generated",
	"docs/generated/db-schema.md",
	"docs/product-specs",
	"docs/product-specs/index.md",
	"docs/product-specs/new-user-onboarding.md",
	"docs/references",
	"docs/references/design-system-reference-llms.txt",
	"docs/references/nixpacks-llms.txt",
	"docs/references/uv-llms.txt",
	"docs/DESIGN.md",
	"docs/FRONTEND.md",
	"docs/PLANS.md",
	"docs/PRODUCT_SENSE.md",
	"docs/QUALITY_SCORE.md",
	"docs/RELIABILITY.md",
	"docs/SECURITY.md",
];
const FLUFF = [
	/\bin order to\b/gi,
	/\bit (is|'s) (important|worth|good) to (note|mention|remember)\b/gi,
	/\bplease note\b/gi,
	/\bas (mentioned|stated|noted) (above|below|earlier|previously)\b/gi,
	/\bneedless to say\b/gi,
	/\bat the end of the day\b/gi,
	/\bbasically\b/gi,
	/\bsimply\b/gi,
	/\bjust\b/gi,
	/\bvery\b/gi,
	/\breally\b/gi,
	/\bactually\b/gi,
	/\bquite\b/gi,
	/\bobviously\b/gi,
	/\bof course\b/gi,
	/\bessentially\b/gi,
	/\butiliz(e|es|ing|ation)\b/gi,
	/\bleverag(e|es|ing)\b/gi,
	/\bin terms of\b/gi,
	/\bthat being said\b/gi,
	/\bfor all intents and purposes\b/gi,
	/\bvarious\b/gi,
	/\bnumerous\b/gi,
	/\ba (wide )?(variety|number) of\b/gi,
];

function walk(path, out = []) {
	let info;
	try {
		info = statSync(path);
	} catch {
		return out;
	}
	if (info.isFile()) {
		out.push(path);
		return out;
	}
	if (!info.isDirectory()) return out;
	let entries;
	try {
		entries = readdirSync(path, { withFileTypes: true });
	} catch {
		return out;
	}
	for (const entry of entries) {
		if (SKIP.has(entry.name)) continue;
		walk(join(path, entry.name), out);
	}
	return out;
}

function isAllowedComment(language, line, text, startLine) {
	const value = text.trim();
	const row = line.trim();
	if (startLine === 1 && row.startsWith("#!")) return true;
	if (/^#\s*shellcheck\b/.test(row)) return true;
	if (
		["js", "jsx", "ts", "tsx"].includes(language) &&
		/^\/\/\/\s*<reference\b/.test(value)
	)
		return true;
	if (
		["js", "jsx", "ts", "tsx"].includes(language) &&
		/^\/\*[*!]\s*@(?:jsx|jsxRuntime|jsxImportSource)\b/.test(value)
	)
		return true;
	if (language === "go" && /^\/\/\s*\+build\b/.test(value)) return true;
	if (
		language === "go" &&
		/^\/\/go:(build|embed|generate|linkname|noescape|noinline|nosplit)\b/.test(
			value,
		)
	)
		return true;
	if (language === "go" && /Code generated .* DO NOT EDIT\./.test(value))
		return true;
	if (language === "go" && /(#cgo|#include|import\s+"C")/.test(value))
		return true;
	if (language === "rust" && /^\/\/!/.test(value)) return true;
	if (language === "rust" && /^\/\/\//.test(value)) return true;
	if (language === "rust" && /^\/\*!/.test(value)) return true;
	if (language === "rust" && /^\/\*\*/.test(value)) return true;
	return false;
}

function commentLanguage(file) {
	const ext = extname(file).toLowerCase();
	if ([".js", ".mjs", ".cjs"].includes(ext)) return "js";
	if (ext === ".jsx") return "jsx";
	if ([".ts", ".mts", ".cts"].includes(ext)) return "ts";
	if (ext === ".tsx") return "tsx";
	if (ext === ".go") return "go";
	if (ext === ".php") return "php";
	if (ext === ".rs") return "rust";
	return "";
}

function scanCodeComments(file, text, relPath) {
	const language = commentLanguage(file);
	const results = [];
	let state = "code";
	let quote = "";
	let escaped = false;
	let line = 1;
	let i = 0;
	while (i < text.length) {
		const char = text[i];
		const next = text[i + 1] ?? "";
		if (state === "line") {
			if (char === "\n") {
				line += 1;
				state = "code";
			}
			i += 1;
			continue;
		}
		if (state === "block") {
			i += 1;
			continue;
		}
		if (char === "\n") {
			line += 1;
			state = state === "line" ? "code" : state;
			escaped = false;
			i += 1;
			continue;
		}
		if (state === "string") {
			if (escaped) {
				escaped = false;
			} else if (char === "\\" && quote !== "`") {
				escaped = true;
			} else if (char === quote) {
				state = "code";
			}
			i += 1;
			continue;
		}
		if (["'", '"', "`"].includes(char)) {
			state = "string";
			quote = char;
			i += 1;
			continue;
		}
		if (char === "/" && next === "/") {
			const end = text.indexOf("\n", i);
			const stop = end === -1 ? text.length : end;
			const value = text.slice(i, stop);
			if (
				!isAllowedComment(
					language,
					text.slice(text.lastIndexOf("\n", i - 1) + 1, stop),
					value,
					line,
				)
			) {
				results.push({
					file: relPath,
					ln: line,
					kind: "line",
					text: value.trim().slice(0, 100),
				});
			}
			state = "line";
			i = stop;
			continue;
		}
		if (char === "/" && next === "*") {
			const end = text.indexOf("*/", i + 2);
			const stop = end === -1 ? text.length : end + 2;
			const value = text.slice(i, stop);
			if (!isAllowedComment(language, "", value, line)) {
				results.push({
					file: relPath,
					ln: line,
					kind: "block",
					text: value.replace(/\s+/g, " ").trim().slice(0, 100),
				});
			}
			line += (value.match(/\n/g) ?? []).length;
			i = stop;
			continue;
		}
		if (language === "php" && char === "#") {
			const end = text.indexOf("\n", i);
			const stop = end === -1 ? text.length : end;
			const value = text.slice(i, stop);
			if (
				!isAllowedComment(
					language,
					text.slice(text.lastIndexOf("\n", i - 1) + 1, stop),
					value,
					line,
				)
			) {
				results.push({
					file: relPath,
					ln: line,
					kind: "line",
					text: value.trim().slice(0, 100),
				});
			}
			state = "line";
			i = stop;
			continue;
		}
		i += 1;
	}
	return results;
}

const allFiles = roots.flatMap((root) => walk(root));
const docFiles = allFiles.filter((file) =>
	DOC_EXTENSIONS.has(extname(file).toLowerCase()),
);
const codeFiles = allFiles.filter((file) =>
	COMMENT_EXTENSIONS.has(extname(file).toLowerCase()),
);
const cwd = process.cwd();
const rel = (path) => relative(cwd, path).replace(/\\/g, "/");
const report = {
	scanned: docFiles.length,
	codeScanned: CHECK_COMMENTS ? codeFiles.length : 0,
	architecture: [],
	comments: [],
	bloat: [],
	fluff: [],
	duplication: [],
	brokenLinks: [],
	structure: [],
	staleMarkers: [],
	totals: { lines: 0, words: 0 },
};
const lineIndex = new Map();

if (CHECK_ARCHITECTURE) {
	for (const requiredPath of REQUIRED_ARCHITECTURE) {
		try {
			statSync(resolve(cwd, requiredPath));
		} catch {
			report.architecture.push({
				path: requiredPath,
				issue: "missing required docs architecture path",
			});
		}
	}
}

if (CHECK_COMMENTS) {
	for (const file of codeFiles) {
		let text;
		try {
			text = readFileSync(file, "utf8");
		} catch {
			continue;
		}
		report.comments.push(...scanCodeComments(file, text, rel(file)));
	}
}

for (const file of docFiles) {
	let text;
	try {
		text = readFileSync(file, "utf8");
	} catch {
		continue;
	}
	const lines = text.split(/\r?\n/);
	const words = text.split(/\s+/).filter(Boolean).length;
	report.totals.lines += lines.length;
	report.totals.words += words;

	if (lines.length > MAX_LINES)
		report.bloat.push({ file: rel(file), lines: lines.length, words });

	const stripInline = (line) => line.replace(/`[^`\n]+`/g, " ");
	let fenced = false;
	const prose = lines.map((line) => {
		if (/^\s*```/.test(line)) {
			fenced = !fenced;
			return "";
		}
		return fenced ? "" : stripInline(line);
	});
	const proseText = prose.join("\n");

	let hits = 0;
	const samples = [];
	for (const re of FLUFF) {
		const matches = proseText.match(re);
		if (matches) {
			hits += matches.length;
			if (samples.length < 4) samples.push(matches[0].toLowerCase());
		}
	}
	const per100 = words ? +((hits / words) * 100).toFixed(2) : 0;
	if (hits >= 5 || per100 >= 1.5) {
		report.fluff.push({
			file: rel(file),
			hits,
			per100w: per100,
			samples: [...new Set(samples)],
		});
	}

	const headings = [];
	fenced = false;
	for (const line of lines) {
		if (/^\s*```/.test(line)) {
			fenced = !fenced;
			continue;
		}
		if (!fenced && /^#{1,6}\s/.test(line)) headings.push(line);
	}
	const h1 = headings.filter((line) => /^#\s/.test(line));
	if (h1.length === 0 && headings.length > 0) {
		report.structure.push({
			file: rel(file),
			issue: "no H1 top-level heading",
		});
	}
	if (h1.length > 1)
		report.structure.push({
			file: rel(file),
			issue: `${h1.length} H1 headings`,
		});
	let prev = 0;
	for (const line of headings) {
		const lvl = line.match(/^#+/)[0].length;
		if (prev && lvl - prev >= 2) {
			report.structure.push({
				file: rel(file),
				issue: `heading jump H${prev}->H${lvl}`,
			});
			break;
		}
		prev = lvl;
	}

	prose.forEach((line, index) => {
		if (!line) return;
		const ln = index + 1;
		const norm = line.trim().toLowerCase().replace(/\s+/g, " ");
		if (norm.length >= 40 && !/^[#>|*\-\d.]/.test(norm)) {
			if (!lineIndex.has(norm)) lineIndex.set(norm, []);
			lineIndex.get(norm).push({ file: rel(file), ln });
		}
		for (const match of line.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
			const target = match[1].split("#")[0].trim();
			if (!target || /^(https?:|mailto:|#|tel:)/.test(target)) continue;
			const abs = resolve(dirname(file), target);
			try {
				statSync(abs);
			} catch {
				report.brokenLinks.push({ file: rel(file), ln, target: match[1] });
			}
		}
		const mark = line.match(/\b(TODO|FIXME|XXX|HACK|DEPRECATED)\b/);
		if (mark) {
			report.staleMarkers.push({
				file: rel(file),
				ln,
				marker: mark[1],
				text: line.trim().slice(0, 80),
			});
		}
		const date = line.match(/\b(20[01]\d|2020|2021|2022|2023)-\d{2}-\d{2}\b/);
		if (date) {
			report.staleMarkers.push({
				file: rel(file),
				ln,
				marker: "old-date",
				text: line.trim().slice(0, 80),
			});
		}
	});
}

for (const [norm, locs] of lineIndex) {
	if (locs.length >= 2) {
		report.duplication.push({
			count: locs.length,
			text: norm.slice(0, 70),
			locs: locs.slice(0, 6),
		});
	}
}
report.duplication.sort((a, b) => b.count - a.count);
report.bloat.sort((a, b) => b.lines - a.lines);
report.fluff.sort((a, b) => b.hits - a.hits);

if (flags.json) {
	console.log(JSON.stringify(report, null, 2));
	process.exit(0);
}

const trunc = (arr, n = TOP) => arr.slice(0, n);
const bar = "-".repeat(60);
console.log(
	`\nDOCS AUDIT - ${report.scanned} docs - ${report.codeScanned} code - ${report.totals.lines} lines - ${report.totals.words} words`,
);
console.log(bar);

function section(title, items, fmt) {
	console.log(`\n## ${title} (${items.length})`);
	if (items.length === 0) {
		console.log("  none");
		return;
	}
	for (const item of trunc(items)) console.log("  " + fmt(item));
	if (items.length > TOP)
		console.log(`  ... and ${items.length - TOP} more (use --json for all)`);
}

section(
	"ARCHITECTURE - create required docs paths",
	report.architecture,
	(item) => `${item.path} - ${item.issue}`,
);
section(
	"COMMENTS - remove nonfunctional code comments",
	report.comments,
	(item) => `${item.file}:${item.ln} ${item.kind} ${item.text}`,
);
section(
	"BLOAT - split or trim",
	report.bloat,
	(item) => `${item.lines}L ${item.words}w ${item.file}`,
);
section(
	"FLUFF - tighten prose",
	report.fluff,
	(item) =>
		`${item.hits} hits (${item.per100w}/100w) ${item.file} [${item.samples.join(", ")}]`,
);
section(
	"DUPLICATION - consolidate",
	report.duplication,
	(item) =>
		`x${item.count} "${item.text}" -> ${item.locs.map((loc) => `${loc.file}:${loc.ln}`).join(", ")}`,
);
section(
	"BROKEN LINKS - fix or drop",
	report.brokenLinks,
	(item) => `${item.file}:${item.ln} -> ${item.target}`,
);
section(
	"STRUCTURE - heading hygiene",
	report.structure,
	(item) => `${item.file} - ${item.issue}`,
);
section(
	"STALE MARKERS - review",
	report.staleMarkers,
	(item) => `${item.file}:${item.ln} [${item.marker}] ${item.text}`,
);

const findings =
	report.architecture.length +
	report.comments.length +
	report.bloat.length +
	report.fluff.length +
	report.duplication.length +
	report.brokenLinks.length +
	report.structure.length +
	report.staleMarkers.length;
console.log(
	`\n${bar}\nTOTAL ${findings} findings. Fix links, architecture, comments, duplication, then bloat/fluff.\n`,
);
process.exit(findings > 0 ? 1 : 0);
