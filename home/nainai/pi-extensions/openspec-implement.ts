/**
 * OpenSpec change implementation.
 *
 * `/openspec-implement <change>` is the git half of `/openspec-apply-change`:
 * it validates the change with the openspec CLI, creates a work branch off the
 * base branch (default `develop`), and only then hands over to the
 * `openspec-apply-change` skill.
 *
 * Branch name: `--branch <name>` wins; otherwise a ticket id (e.g. `KC-123`)
 * found in the change's markdown gives `KC-123/<change>`; otherwise
 * `openspec/<change>`.
 *
 * The change is resolved by the extension (not by the agent) so a missing
 * change or a broken openspec CLI aborts loudly instead of the agent
 * implementing a guess. The two-phase discipline (audit -> open points gate ->
 * implement) lives in `openspec/config.yaml` under `operations.apply.guidance`
 * and is repeated here so it survives a stale config.
 *
 * Options:
 *   --base <branch>    base branch (default develop)
 *   --branch <name>    explicit work branch name (skips ticket auto-detection)
 *   --no-branch        stay on the current branch
 *   --worktree [path]  create the branch in a git worktree instead of switching
 *                      the current checkout (default path: ../<repo>-<change>)
 *   --extra "<text>"   extra instruction appended to the prompt
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import fs from "node:fs/promises";
import path from "node:path";

const DEFAULT_BASE = "develop";

type ParsedArgs =
	| {
			ok: true;
			change?: string;
			base: string;
			branch: boolean;
			branchName?: string;
			worktree: boolean;
			worktreePath?: string;
			extra?: string;
	  }
	| { ok: false; error: string };

function parseArgs(args: string | undefined): ParsedArgs {
	const tokens = args?.trim().split(/\s+/).filter(Boolean) ?? [];
	let change: string | undefined;
	let base = DEFAULT_BASE;
	let branch = true;
	let branchName: string | undefined;
	let worktree = false;
	let worktreePath: string | undefined;
	let extra: string | undefined;

	const readValue = (name: string, index: number): { value?: string; consumed: boolean } => {
		const token = tokens[index];
		if (token.startsWith(`${name}=`)) return { value: token.slice(name.length + 1), consumed: false };
		return { value: tokens[index + 1], consumed: true };
	};

	for (let i = 0; i < tokens.length; i++) {
		const token = tokens[i];
		if (token === "--no-branch") {
			branch = false;
			continue;
		}
		if (token === "--worktree" || token.startsWith("--worktree=")) {
			worktree = true;
			if (token.startsWith("--worktree=")) {
				const value = token.slice("--worktree=".length).trim();
				if (!value) return { ok: false, error: "--worktree= requires a path" };
				worktreePath = value;
				continue;
			}
			// Bare `--worktree` may be followed by an optional path. A following token
			// is only a path if the change name was already given; otherwise it is the
			// change name.
			const next = tokens[i + 1];
			if (next && !next.startsWith("-") && change) {
				worktreePath = next;
				i++;
			}
			continue;
		}
		if (token === "--branch" || token.startsWith("--branch=")) {
			const { value, consumed } = readValue("--branch", i);
			if (!value?.trim()) return { ok: false, error: "--branch requires a value" };
			branchName = value.trim();
			if (consumed) i++;
			continue;
		}
		if (token === "--base" || token.startsWith("--base=")) {
			const { value, consumed } = readValue("--base", i);
			if (!value?.trim()) return { ok: false, error: "--base requires a value" };
			base = value.trim();
			if (consumed) i++;
			continue;
		}
		if (token === "--extra" || token.startsWith("--extra=")) {
			const value = token.startsWith("--extra=") ? token.slice("--extra=".length) : tokens.slice(i + 1).join(" ");
			if (!value.trim()) return { ok: false, error: "--extra requires a value" };
			extra = value.trim().replace(/^["']|["']$/g, "");
			if (!token.startsWith("--extra=")) i = tokens.length;
			continue;
		}
		if (token.startsWith("-")) return { ok: false, error: `Unknown argument '${token}'` };
		if (change) return { ok: false, error: `Only one change name allowed (got '${change}' and '${token}')` };
		change = token;
	}
	if (worktree && !branch) return { ok: false, error: "--worktree and --no-branch are mutually exclusive" };
	if (branchName && !branch) return { ok: false, error: "--branch and --no-branch are mutually exclusive" };
	return { ok: true, change, base, branch, branchName, worktree, worktreePath, extra };
}

type ChangeEntry = { name: string; completedTasks?: number; totalTasks?: number; status?: string };

async function listChanges(pi: ExtensionAPI): Promise<{ ok: true; changes: ChangeEntry[] } | { ok: false; error: string }> {
	let result: { stdout: string; stderr: string; code: number };
	try {
		result = await pi.exec("openspec", ["list", "--json"]);
	} catch (error) {
		return { ok: false, error: `openspec CLI not runnable: ${error instanceof Error ? error.message : String(error)}` };
	}
	if (result.code !== 0) return { ok: false, error: result.stderr.trim() || `openspec exited with code ${result.code}` };
	try {
		const parsed = JSON.parse(result.stdout) as { changes?: ChangeEntry[] };
		const changes = parsed.changes;
		if (!Array.isArray(changes)) return { ok: false, error: "openspec list --json returned no 'changes' array" };
		return { ok: true, changes };
	} catch (error) {
		return { ok: false, error: `could not parse openspec list --json: ${error instanceof Error ? error.message : String(error)}` };
	}
}

type Artifact = { id: string; status?: string };
type Status = { schemaName?: string; artifacts?: Artifact[]; applyRequires?: string[] };

async function changeStatus(pi: ExtensionAPI, change: string): Promise<{ ok: true; status: Status } | { ok: false; error: string }> {
	const { stdout, stderr, code } = await pi.exec("openspec", ["status", "--change", change, "--json"]);
	if (code !== 0) return { ok: false, error: stderr.trim() || `openspec status exited with code ${code}` };
	try {
		return { ok: true, status: JSON.parse(stdout) as Status };
	} catch (error) {
		return { ok: false, error: `could not parse openspec status --json: ${error instanceof Error ? error.message : String(error)}` };
	}
}

/** Artifacts required before apply that are not done yet; apply must not start on these. */
function missingApplyArtifacts(status: Status): string[] {
	const required = status.applyRequires ?? [];
	const byId = new Map((status.artifacts ?? []).map((a) => [a.id, a.status]));
	return required.filter((id) => byId.get(id) !== "done");
}

const TICKET_RE = /\b[A-Z][A-Z0-9]{1,9}-\d+\b/;

/**
 * First ticket id mentioned in the change's markdown (proposal first, since that
 * is where the link to the tracker is written). Used as branch prefix so the
 * tracker can associate the branch with the ticket.
 */
async function detectTicket(changeDir: string): Promise<string | null> {
	let entries: string[];
	try {
		entries = (await fs.readdir(changeDir)).filter((f) => f.endsWith(".md"));
	} catch {
		return null;
	}
	entries.sort((a, b) => Number(b.startsWith("proposal")) - Number(a.startsWith("proposal")));
	for (const entry of entries) {
		let text: string;
		try {
			text = await fs.readFile(path.join(changeDir, entry), "utf8");
		} catch {
			continue;
		}
		const match = TICKET_RE.exec(text);
		if (match) return match[0];
	}
	return null;
}

async function hasUncommittedChanges(pi: ExtensionAPI): Promise<boolean> {
	const { stdout, code } = await pi.exec("git", ["status", "--porcelain"]);
	// Fail closed: an unknown worktree state must not be branched away from.
	if (code !== 0) return true;
	return stdout
		.split("\n")
		.filter((l) => l.trim())
		.some((l) => !l.startsWith("??"));
}

async function remoteName(pi: ExtensionAPI): Promise<string | null> {
	const { stdout, code } = await pi.exec("git", ["remote"]);
	if (code !== 0) return null;
	const remotes = stdout
		.split("\n")
		.map((r) => r.trim())
		.filter(Boolean);
	if (remotes.length === 0) return null;
	return remotes.includes("origin") ? "origin" : remotes[0];
}

async function branchExists(pi: ExtensionAPI, name: string): Promise<boolean> {
	const { code } = await pi.exec("git", ["rev-parse", "--verify", "--quiet", `refs/heads/${name}`]);
	return code === 0;
}

async function repoRoot(pi: ExtensionAPI): Promise<string | null> {
	const { stdout, code } = await pi.exec("git", ["rev-parse", "--show-toplevel"]);
	if (code !== 0 || !stdout.trim()) return null;
	return stdout.trim();
}

async function currentBranch(pi: ExtensionAPI): Promise<string | null> {
	const { stdout, code } = await pi.exec("git", ["rev-parse", "--abbrev-ref", "HEAD"]);
	const branch = stdout.trim();
	if (code !== 0 || !branch || branch === "HEAD") return null;
	return branch;
}

/**
 * Creates `<name>` off `<remote>/<base>`, falling back to a local base branch
 * when there is no remote or the fetch fails. With `worktreePath` the branch is
 * checked out in a new git worktree and the current checkout stays untouched.
 */
async function createWorkBranch(
	pi: ExtensionAPI,
	name: string,
	base: string,
	worktreePath?: string,
): Promise<{ ok: true; startPoint: string } | { ok: false; error: string }> {
	const remote = await remoteName(pi);
	let startPoint: string | undefined;
	let fetchProblem = "no remote configured";

	if (remote) {
		const { code, stderr } = await pi.exec("git", ["fetch", remote, base]);
		if (code === 0) startPoint = `${remote}/${base}`;
		else fetchProblem = `git fetch ${remote} ${base} failed (${stderr.trim() || `exit ${code}`})`;
	}
	if (!startPoint) {
		// Local base is used only when the remote base is unreachable; the agent is
		// told about it in the prompt so the staleness is visible.
		if (!(await branchExists(pi, base))) return { ok: false, error: `${fetchProblem} and no local '${base}'` };
		startPoint = base;
	}

	const argv = worktreePath
		? ["worktree", "add", "-b", name, worktreePath, startPoint]
		: ["checkout", "-b", name, startPoint];
	const { code, stderr } = await pi.exec("git", argv);
	if (code !== 0) return { ok: false, error: stderr.trim() || `git ${argv.join(" ")} exited with ${code}` };
	return { ok: true, startPoint };
}

function buildPrompt(input: {
	change: string;
	schemaName?: string;
	branch: string | null;
	base: string;
	startPoint?: string;
	worktreePath?: string;
	extra?: string;
}): string {
	const branchLine = input.branch ? `Work branch: \`${input.branch}\`` : "Work branch: (detached HEAD)";
	const baseLine = input.startPoint
		? `Base branch: \`${input.base}\` (branched from \`${input.startPoint}\`)`
		: `Base branch: \`${input.base}\` (branch not created by this command)`;
	const staleLine =
		input.startPoint && !input.startPoint.includes("/")
			? `\nNote: the remote base was unreachable, so the branch starts from the LOCAL \`${input.base}\`, which may be stale.`
			: "";
	const worktreeLine = input.worktreePath
		? `\nWorktree: \`${input.worktreePath}\` — the current checkout is on a different branch.\nRun every read, edit and command against paths under that worktree, not the cwd.`
		: "";
	const schemaLine = input.schemaName ? `\nSchema: \`${input.schemaName}\`` : "";
	const extraBlock = input.extra ? `\n\n## Additional instruction from the user\n\n${input.extra}` : "";

	return `Implement OpenSpec change \`${input.change}\`. Work in two phases and do not skip phase 1.

${branchLine}
${baseLine}${staleLine}${worktreeLine}${schemaLine}

Follow the \`openspec-apply-change\` skill for the mechanics (status, apply
instructions, context files, task checkboxes). The change is already selected and
validated — use \`${input.change}\`, do not ask which one. Treat the
\`operationGuidance\` returned by the CLI as additive advice on top of the phases
below; where both say the same thing, the stricter reading wins.

## Phase 1 — audit (read-only, no edits)

After reading the context files, apply the \`fact-check\` skill to the existing
code the tasks touch.

1. Locate that code (grep/find, read the files).
2. Audit it for: silent error swallowing, inaccurate fallbacks/defaults that mask
   misconfiguration, wishful thinking (unvalidated boundaries, "can't fail" code),
   and plain logic errors.
3. Report every finding as \`file:line — risk\`. If you find nothing, say so; do not
   invent problems.
4. Do NOT edit any file in this phase.
5. State explicitly which tasks are underspecified.

## Phase 1b — open points (mandatory gate)

End phase 1 with an "Open points" list containing every item where you would
otherwise have to decide for the user:

- ambiguous or contradictory tasks or spec requirements,
- findings from the audit whose fix is in scope vs. a separate change,
- design choices with more than one defensible option (name the options),
- anything you would only be guessing about.

If that list is non-empty: STOP. Ask the user, numbered, with your recommendation
per item, and wait for the answer. Do not start phase 2, do not edit files, do not
pick a default "to keep going".

Only if the list is genuinely empty, write "Open points: none" and continue.

## Phase 2 — implement

Only after phase 1 is reported and every open point has been answered by the user:

1. Implement exactly what the tasks ask, one task at a time, marking each
   \`- [ ]\` → \`- [x]\` only when its specified behavior is fully implemented.
2. Do not expand scope; list out-of-scope findings from phase 1 separately instead
   of fixing them silently.
3. Follow the existing patterns of the codebase (PATTERN/AGENTS/CLAUDE files if present).
4. Fail loud over fail silent: no bare catch, no \`|| true\`, no default value that
   hides a real failure. Every fallback needs a stated reason why that value is
   correct for the failure case.
5. Run the verification commands the tasks require and report the real output — do
   not claim a command succeeded without running it.

## Final report

- Task/acceptance criteria coverage (or why not covered).
- Files changed with a one-line reason each.
- Phase 1 findings that were fixed vs. left open (with reason).
- Verification commands run and their actual results.
- Open questions for the human reviewer.${extraBlock}`;
}

export default function openspecImplementExtension(pi: ExtensionAPI) {
	pi.registerCommand("openspec-implement", {
		description:
			'Branch then fact-check and implement an OpenSpec change: /openspec-implement <change> [--base develop] [--branch <name>] [--worktree [path]] [--no-branch] [--extra "..."]',
		handler: async (args, ctx: ExtensionCommandContext) => {
			const parsed = parseArgs(args);
			if (!parsed.ok) {
				ctx.ui.notify(
					`${parsed.error}. Usage: /openspec-implement <change> [--base <branch>] [--branch <name>] [--worktree [path]] [--no-branch] [--extra "..."]`,
					"error",
				);
				return;
			}

			const { code: repoCode } = await pi.exec("git", ["rev-parse", "--git-dir"]);
			if (repoCode !== 0) {
				ctx.ui.notify("Not a git repository", "error");
				return;
			}

			const listed = await listChanges(pi);
			if (!listed.ok) {
				// Abort instead of continuing: without the change list the agent would
				// implement a guess.
				ctx.ui.notify(`Could not list OpenSpec changes: ${listed.error}`, "error");
				return;
			}

			let change = parsed.change;
			if (!change) {
				const active = listed.changes.filter((c) => c.status !== "complete");
				if (active.length === 1) change = active[0].name;
				else if (active.length === 0) {
					ctx.ui.notify("No active OpenSpec changes. Create one with /openspec-propose.", "error");
					return;
				} else {
					const names = active
						.map((c) => `${c.name} (${c.completedTasks ?? 0}/${c.totalTasks ?? 0})`)
						.join(", ");
					ctx.ui.notify(`Multiple active changes — pass one: ${names}`, "error");
					return;
				}
			} else if (!listed.changes.some((c) => c.name === change)) {
				const names = listed.changes.map((c) => c.name).join(", ") || "(none)";
				ctx.ui.notify(`Unknown change '${change}'. Available: ${names}`, "error");
				return;
			}

			const status = await changeStatus(pi, change);
			if (!status.ok) {
				ctx.ui.notify(`Could not read status of '${change}': ${status.error}`, "error");
				return;
			}
			// Branching for a change whose tasks do not exist yet would leave an empty
			// branch and send the agent implementing from an incomplete plan.
			const missing = missingApplyArtifacts(status.status);
			if (missing.length > 0) {
				ctx.ui.notify(`'${change}' is not ready to apply — missing artifact(s): ${missing.join(", ")}. Use /openspec-update-change first.`, "error");
				return;
			}

			let startPoint: string | undefined;
			let worktreePath: string | undefined;
			let workBranch: string | undefined;
			if (parsed.branch) {
				let branchName = parsed.branchName;
				if (!branchName) {
					const root = await repoRoot(pi);
					const ticket = root ? await detectTicket(path.join(root, "openspec", "changes", change)) : null;
					branchName = ticket ? `${ticket}/${change}` : `openspec/${change}`;
				}
				if (await branchExists(pi, branchName)) {
					ctx.ui.notify(`Branch '${branchName}' already exists. Check it out or pass --no-branch.`, "error");
					return;
				}

				// A worktree leaves the current checkout alone, so dirty files are fine there.
				if (!parsed.worktree && (await hasUncommittedChanges(pi))) {
					ctx.ui.notify("Uncommitted changes present. Commit or stash before branching.", "error");
					return;
				}

				if (parsed.worktree) {
					const root = await repoRoot(pi);
					if (!root) {
						ctx.ui.notify("Could not determine the repository root for the worktree.", "error");
						return;
					}
					worktreePath = parsed.worktreePath
						? path.resolve(ctx.cwd, parsed.worktreePath)
						: path.join(path.dirname(root), `${path.basename(root)}-${change}`);
				}

				const location = worktreePath ? ` in worktree ${worktreePath}` : "";
				ctx.ui.notify(`Creating branch ${branchName} from ${parsed.base}${location}...`, "info");
				const created = await createWorkBranch(pi, branchName, parsed.base, worktreePath);
				if (!created.ok) {
					ctx.ui.notify(`Branch creation failed: ${created.error}`, "error");
					return;
				}
				startPoint = created.startPoint;
				workBranch = branchName;
			}

			// Without a worktree the cwd checkout carries the work branch; with one the
			// cwd stays on the old branch, so report the created branch instead.
			const branch = workBranch ?? (await currentBranch(pi));
			ctx.ui.notify(`Audit + implement ${change}${branch ? ` on ${branch}` : ""}`, "info");

			pi.sendUserMessage(
				buildPrompt({
					change,
					schemaName: status.status.schemaName,
					branch,
					base: parsed.base,
					startPoint,
					worktreePath,
					extra: parsed.extra,
				}),
			);
		},
	});
}
