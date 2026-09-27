#!/usr/bin/env node
/**
 * agent-memory — seeding CLI for the store defined in openspec/specs/agent-memory/design.md.
 *
 * Deliberately outside the agent: the read path in pi stays read-only, so a bad
 * fact can only get in through a human running this.
 *
 *   agent-memory add <subject> <predicate> <value...>  [--global]
 *   agent-memory list [--all]
 *   agent-memory forget <id>
 *   agent-memory path
 *
 * Scope defaults to the current git root (repo store if <root>/.pi/memory exists,
 * else the global store with scope=<root>). --global forces scope "global".
 */

import { promises as fs } from "node:fs";
import { createHash, randomUUID } from "node:crypto";
import { homedir } from "node:os";
import path from "node:path";

const GLOBAL_STORE = path.join(
	process.env.XDG_STATE_HOME || path.join(homedir(), ".local", "state"),
	"agent-memory",
);
const MAX_RECORD_BYTES = 4096; // O_APPEND line atomicity (SPEC §6)

const die = (msg) => {
	console.error(`agent-memory: ${msg}`);
	process.exit(1);
};

async function isDir(p) {
	try {
		return (await fs.stat(p)).isDirectory();
	} catch {
		return false;
	}
}

async function findRepoRoot(cwd) {
	let dir = path.resolve(cwd);
	for (;;) {
		if (await isDir(path.join(dir, ".git"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) return null;
		dir = parent;
	}
}

async function resolveTarget({ forceGlobal }) {
	const root = await findRepoRoot(process.cwd());
	if (forceGlobal || !root) return { store: GLOBAL_STORE, scope: "global" };
	const repoStore = path.join(root, ".pi", "memory");
	return (await isDir(repoStore))
		? { store: repoStore, scope: root }
		: { store: GLOBAL_STORE, scope: root };
}

const factsFile = (store) => path.join(store, "semantic", "facts.jsonl");

async function readFacts(store) {
	let raw;
	try {
		raw = await fs.readFile(factsFile(store), "utf8");
	} catch {
		return [];
	}
	return raw
		.split("\n")
		.filter((l) => l.trim())
		.map((l, i) => {
			try {
				return JSON.parse(l);
			} catch {
				return { __corrupt: true, __line: i + 1, __raw: l };
			}
		});
}

async function appendFact(store, fact) {
	const line = `${JSON.stringify(fact)}\n`;
	if (Buffer.byteLength(line) > MAX_RECORD_BYTES)
		die(`record exceeds ${MAX_RECORD_BYTES} bytes; shorten the value`);
	await fs.mkdir(path.dirname(factsFile(store)), { recursive: true });
	await fs.appendFile(factsFile(store), line, { flag: "a" });
}

/** Rewrites are tmp+rename; never truncate a file that holds data (SPEC §5). */
async function rewriteFacts(store, facts) {
	const file = factsFile(store);
	const body = facts
		.map((f) => (f.__corrupt ? f.__raw : JSON.stringify(f)))
		.join("\n");
	const tmp = `${file}.tmp.${process.pid}`;
	const fh = await fs.open(tmp, "w");
	try {
		await fh.writeFile(`${body}\n`);
		await fh.sync();
	} finally {
		await fh.close();
	}
	await fs.rename(tmp, file);
}

const live = (f) =>
	!f.__corrupt && f.superseded_by === null && f.value !== null && f.origin === "user";

async function withLock(store, fn) {
	await fs.mkdir(store, { recursive: true });
	const lock = path.join(store, ".lock");
	let fh;
	try {
		fh = await fs.open(lock, "wx");
	} catch {
		die(`store is locked (${lock}); remove it if no other process is writing`);
	}
	try {
		return await fn();
	} finally {
		await fh.close();
		await fs.rm(lock, { force: true });
	}
}

// ── commands ────────────────────────────────────────────────────────────────

async function cmdAdd(args, flags) {
	const [subject, predicate, ...rest] = args;
	const value = rest.join(" ").trim();
	if (!subject || !predicate || !value)
		die("usage: agent-memory add <subject> <predicate> <value...> [--global]");

	const { store, scope } = await resolveTarget(flags);
	await withLock(store, async () => {
		const facts = await readFacts(store);
		const prior = facts.find(
			(f) => live(f) && f.scope === scope && f.subject === subject && f.predicate === predicate,
		);
		const fact = {
			id: randomUUID(),
			ts: new Date().toISOString().replace(/\.\d+Z$/, "Z"),
			schema: 1,
			scope,
			subject,
			predicate,
			value,
			source: "cli",
			origin: "user",
			superseded_by: null,
		};
		// Supersede, never overwrite: the old value stays readable in git history.
		if (prior) {
			prior.superseded_by = fact.id;
			facts.push(fact);
			await rewriteFacts(store, facts);
			console.log(`superseded ${prior.id} (was: ${prior.value})`);
		} else {
			await appendFact(store, fact);
		}
		console.log(`${fact.id}  [${scope}] ${subject} ${predicate} = ${value}`);
	});
}

async function cmdForget(args) {
	const [id] = args;
	if (!id) die("usage: agent-memory forget <id>");
	const root = await findRepoRoot(process.cwd());
	const stores = [GLOBAL_STORE, ...(root ? [path.join(root, ".pi", "memory")] : [])];
	for (const store of stores) {
		if (!(await readFacts(store)).some((f) => !f.__corrupt && f.id?.startsWith(id))) continue;
		const forgotten = await withLock(store, async () => {
			// Re-read under the lock: a concurrent add must not be clobbered by a stale rewrite.
			const facts = await readFacts(store);
			const target = facts.find((f) => !f.__corrupt && f.id?.startsWith(id));
			if (!target) return null;
			const tombstone = {
				...target,
				id: randomUUID(),
				ts: new Date().toISOString().replace(/\.\d+Z$/, "Z"),
				value: null,
				source: "cli",
				superseded_by: null,
			};
			target.superseded_by = tombstone.id;
			facts.push(tombstone);
			await rewriteFacts(store, facts);
			return target;
		});
		if (!forgotten) continue;
		console.log(`forgot ${forgotten.id}: ${forgotten.subject} ${forgotten.predicate}`);
		return;
	}
	die(`no fact with id prefix ${id}`);
}

async function cmdList(flags) {
	const root = await findRepoRoot(process.cwd());
	const stores = [GLOBAL_STORE, ...(root ? [path.join(root, ".pi", "memory")] : [])];
	let n = 0;
	for (const store of stores) {
		for (const f of await readFacts(store)) {
			if (f.__corrupt) {
				console.log(`!! ${path.basename(store)}:${f.__line} corrupt line`);
				continue;
			}
			if (!flags.all && !live(f)) continue;
			const state = live(f) ? "  " : "x ";
			console.log(
				`${state}${f.id.slice(0, 8)}  [${f.scope}] ${f.subject} ${f.predicate} = ${f.value}`,
			);
			n++;
		}
	}
	if (n === 0) console.log("no facts");
}

const [cmd, ...rest] = process.argv.slice(2);
const flags = {
	global: rest.includes("--global"),
	all: rest.includes("--all"),
};
flags.forceGlobal = flags.global;
const args = rest.filter((a) => !a.startsWith("--"));

switch (cmd) {
	case "add":
		await cmdAdd(args, flags);
		break;
	case "forget":
		await cmdForget(args);
		break;
	case "list":
		await cmdList(flags);
		break;
	case "path": {
		const t = await resolveTarget(flags);
		console.log(`${t.store}  (scope: ${t.scope})`);
		break;
	}
	default:
		console.log(
			[
				"agent-memory add <subject> <predicate> <value...> [--global]",
				"agent-memory list [--all]",
				"agent-memory forget <id>",
				"agent-memory path [--global]",
			].join("\n"),
		);
		process.exit(cmd ? 1 : 0);
}
