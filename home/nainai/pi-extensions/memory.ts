/**
 * Agent memory — step 1: read-only working-memory injection.
 *
 * Reads the on-disk stores defined in openspec/specs/agent-memory/design.md and injects a
 * scoped block on the first turn of a session. Writes nothing: seeding facts is a
 * manual edit of semantic/facts.jsonl until the read path proves useful.
 *
 * Stores (overlay, repo wins):
 *   global: $XDG_STATE_HOME/agent-memory   (default ~/.local/state/agent-memory)
 *   repo:   <git-root>/.pi/memory          (only when the dir exists)
 *
 * `/memory` shows what would be injected for the current cwd.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

// ── Spec types ──────────────────────────────────────────────────────────────

type Fact = {
	id: string;
	ts: string;
	scope: string;
	subject: string;
	predicate: string;
	value: string | null;
	origin: "user" | "agent-proposed";
	superseded_by: string | null;
};

type Episode = {
	id: string;
	ts: string;
	scope: string;
	task: string;
	outcome: "success" | "partial" | "failed" | "abandoned";
	summary: string;
	failures?: string[];
};

type Config = {
	injection_budget_chars: number;
	max_episodes_injected: number;
};

const DEFAULT_CONFIG: Config = { injection_budget_chars: 6000, max_episodes_injected: 3 };

const GLOBAL_STORE = path.join(
	process.env.XDG_STATE_HOME || path.join(homedir(), ".local", "state"),
	"agent-memory",
);
const REPO_STORE_SUFFIX = path.join(".pi", "memory");

// ── Reading ─────────────────────────────────────────────────────────────────

async function readJsonl<T>(file: string): Promise<T[]> {
	let raw: string;
	try {
		raw = await fs.readFile(file, "utf8");
	} catch {
		return [];
	}
	const out: T[] = [];
	for (const line of raw.split("\n")) {
		const trimmed = line.trim();
		if (!trimmed) continue;
		try {
			out.push(JSON.parse(trimmed) as T);
		} catch {
			// A corrupt line must not take down the session; the prune pass reports it.
		}
	}
	return out;
}

async function readConfig(store: string): Promise<Config> {
	try {
		const parsed = JSON.parse(await fs.readFile(path.join(store, "config.json"), "utf8"));
		return {
			injection_budget_chars:
				typeof parsed.injection_budget_chars === "number"
					? parsed.injection_budget_chars
					: DEFAULT_CONFIG.injection_budget_chars,
			max_episodes_injected:
				typeof parsed.max_episodes_injected === "number"
					? parsed.max_episodes_injected
					: DEFAULT_CONFIG.max_episodes_injected,
		};
	} catch {
		return DEFAULT_CONFIG;
	}
}

async function readEpisodes(store: string): Promise<Episode[]> {
	const dir = path.join(store, "episodic");
	let names: string[];
	try {
		names = await fs.readdir(dir);
	} catch {
		return [];
	}
	const files = names.filter((n) => n.endsWith(".jsonl")).sort();
	const out: Episode[] = [];
	for (const name of files) out.push(...(await readJsonl<Episode>(path.join(dir, name))));
	return out;
}

async function readNotes(store: string, scope: string): Promise<string[]> {
	const dir = path.join(store, "semantic");
	let names: string[];
	try {
		names = await fs.readdir(dir);
	} catch {
		return [];
	}
	const slug = path.basename(scope);
	const out: string[] = [];
	for (const name of names.filter((n) => n.endsWith(".md")).sort()) {
		if (path.basename(name, ".md") !== slug) continue;
		out.push((await fs.readFile(path.join(dir, name), "utf8")).trim());
	}
	return out;
}

async function isDir(p: string): Promise<boolean> {
	try {
		return (await fs.stat(p)).isDirectory();
	} catch {
		return false;
	}
}

async function findRepoRoot(cwd: string): Promise<string | null> {
	let dir = path.resolve(cwd);
	for (;;) {
		if (await isDir(path.join(dir, ".git"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) return null;
		dir = parent;
	}
}

// ── Selection (SPEC §3) ─────────────────────────────────────────────────────

function factKey(f: Fact): string {
	return `${f.scope}\u0000${f.subject}\u0000${f.predicate}`;
}

/** Live = not superseded, not tombstoned, user-authored. Repo store wins on key collision. */
function liveFacts(globalFacts: Fact[], repoFacts: Fact[]): Fact[] {
	const byKey = new Map<string, Fact>();
	for (const f of [...globalFacts, ...repoFacts]) {
		if (f.superseded_by !== null || f.value === null || f.origin !== "user") continue;
		byKey.set(factKey(f), f);
	}
	return [...byKey.values()];
}

function tokenize(text: string): Set<string> {
	return new Set(
		text
			.toLowerCase()
			.split(/[^a-z0-9_/.-]+/)
			.filter((t) => t.length > 2),
	);
}

function overlap(query: Set<string>, text: string): number {
	let n = 0;
	for (const t of tokenize(text)) if (query.has(t)) n++;
	return n;
}

function inScope(recordScope: string, repoRoot: string | null): boolean {
	return recordScope === "global" || (repoRoot !== null && recordScope === repoRoot);
}

function renderFact(f: Fact): string {
	return `FACT ${f.subject} ${f.predicate} = ${f.value}`;
}

function renderEpisode(e: Episode): string {
	const failures = e.failures?.length ? ` | wrong turns: ${e.failures.join("; ")}` : "";
	return `PAST ${e.task} (${e.outcome}): ${e.summary}${failures}`;
}

type Selection = { lines: string[]; omitted: number; scope: string };

function select(
	facts: Fact[],
	episodes: Episode[],
	notes: string[],
	repoRoot: string | null,
	prompt: string,
	config: Config,
): Selection {
	const query = tokenize(prompt);
	const scoped = facts.filter((f) => inScope(f.scope, repoRoot));

	// Repo facts before global ones; keyword overlap only breaks ties within a tier.
	const rank = (a: string, b: string, scopeA: string, scopeB: string) => {
		const tier = (s: string) => (s === "global" ? 1 : 0);
		if (tier(scopeA) !== tier(scopeB)) return tier(scopeA) - tier(scopeB);
		return overlap(query, b) - overlap(query, a);
	};
	scoped.sort((a, b) => rank(renderFact(a), renderFact(b), a.scope, b.scope));

	const scopedEpisodes = episodes
		.filter((e) => inScope(e.scope, repoRoot))
		.sort((a, b) => {
			const failed = (e: Episode) => (e.failures?.length ? 0 : 1);
			if (failed(a) !== failed(b)) return failed(a) - failed(b);
			const byOverlap = overlap(query, renderEpisode(b)) - overlap(query, renderEpisode(a));
			return byOverlap !== 0 ? byOverlap : b.ts.localeCompare(a.ts);
		})
		.slice(0, config.max_episodes_injected);

	const candidates = [
		...scoped.map(renderFact),
		...notes.map((n) => `NOTE\n${n}`),
		...scopedEpisodes.map(renderEpisode),
	];

	// Whole records only — a truncated fact is worse than a missing one. Stop at the
	// first overflow instead of best-fit packing, so a short low-priority record can
	// never displace a longer higher-priority one.
	const lines: string[] = [];
	let used = 0;
	let i = 0;
	for (; i < candidates.length; i++) {
		const c = candidates[i];
		if (used + c.length + 1 > config.injection_budget_chars) break;
		lines.push(c);
		used += c.length + 1;
	}
	return { lines, omitted: candidates.length - i, scope: repoRoot ?? "global" };
}

function renderBlock(sel: Selection): string | null {
	if (sel.lines.length === 0) return null;
	const tail = sel.omitted > 0 ? `\n[memory: ${sel.omitted} records omitted]` : "";
	return [
		`<agent-memory scope="${sel.scope}" records="${sel.lines.length}">`,
		...sel.lines,
		`</agent-memory>${tail}`,
	].join("\n");
}

// ── Store resolution ────────────────────────────────────────────────────────

async function collect(cwd: string, prompt: string): Promise<Selection> {
	const repoRoot = await findRepoRoot(cwd);
	const repoStore = repoRoot ? path.join(repoRoot, REPO_STORE_SUFFIX) : null;
	const stores = [GLOBAL_STORE, ...(repoStore && (await isDir(repoStore)) ? [repoStore] : [])];

	const config = await readConfig(stores[stores.length - 1]);
	const facts: Fact[][] = [];
	const episodes: Episode[] = [];
	const notes: string[] = [];
	for (const store of stores) {
		facts.push(await readJsonl<Fact>(path.join(store, "semantic", "facts.jsonl")));
		episodes.push(...(await readEpisodes(store)));
		if (repoRoot) notes.push(...(await readNotes(store, repoRoot)));
	}

	return select(
		liveFacts(facts[0] ?? [], facts[1] ?? []),
		episodes,
		notes,
		repoRoot,
		prompt,
		config,
	);
}

// ── Extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	let injectedThisSession = false;

	pi.on("session_start", async () => {
		injectedThisSession = false;
	});

	pi.on("before_agent_start", async (event, ctx: ExtensionContext) => {
		if (injectedThisSession) return;
		injectedThisSession = true;

		const block = renderBlock(await collect(ctx.cwd, event.prompt ?? ""));
		if (!block) return;

		return {
			message: {
				customType: "agent-memory",
				content: block,
				display: false,
			},
		};
	});

	pi.registerCommand("memory", {
		description: "Show the memory block that would be injected for this cwd",
		handler: async (_args: string, ctx: ExtensionContext) => {
			const sel = await collect(ctx.cwd, "");
			const block = renderBlock(sel);
			ctx.ui.notify(
				block ?? `no memory for scope ${sel.scope}\nglobal store: ${GLOBAL_STORE}`,
				"info",
			);
		},
	});
}
