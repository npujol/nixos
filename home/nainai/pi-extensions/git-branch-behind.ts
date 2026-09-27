/**
 * git-branch-behind
 *
 * Fixes "source branch is N commits behind the target branch" when both
 * branches are protected (no push, no force-push). The only legal move is
 * adding a merge commit to SOURCE via a separate MR, so this extension
 * prepares that merge branch locally and prints the commands to run.
 *
 *   /branch-behind                    - interactive (asks SOURCE/TARGET)
 *   /branch-behind develop main       - merge origin/main into develop
 *   /branch-behind develop main --remote upstream
 *
 * Nothing is pushed and no MR is created; the user runs the printed commands.
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

type Args = { source: string; target: string; remote: string };

function parseArgs(raw: string | undefined): Args | { error: string } {
	const tokens = raw?.trim().split(/\s+/).filter(Boolean) ?? [];
	let remote = "origin";
	const positional: string[] = [];

	for (let i = 0; i < tokens.length; i++) {
		const token = tokens[i];
		if (token === "--remote") {
			const value = tokens[i + 1]?.trim();
			if (!value) return { error: "--remote requires a remote name (e.g. --remote upstream)." };
			remote = value;
			i++;
		} else if (token.startsWith("--remote=")) {
			const value = token.slice("--remote=".length).trim();
			if (!value) return { error: "--remote requires a remote name (e.g. --remote=upstream)." };
			remote = value;
		} else {
			positional.push(token);
		}
	}

	if (positional.length > 2) {
		return { error: "Usage: /branch-behind [<source>] [<target>] [--remote <name>]" };
	}

	return { source: positional[0] ?? "", target: positional[1] ?? "", remote };
}

async function git(pi: ExtensionAPI, args: string[]) {
	return pi.exec("git", args);
}

async function requireClean(pi: ExtensionAPI): Promise<string | null> {
	const { stdout, code } = await git(pi, ["status", "--porcelain"]);
	// Fail closed: an unknown working-tree state must not trigger a checkout.
	if (code !== 0) return "git status failed; refusing to touch the working tree.";
	const dirty = stdout
		.trim()
		.split("\n")
		.filter((l) => l.trim() && !l.startsWith("??"));
	return dirty.length > 0 ? "Uncommitted changes present. Commit or stash them first." : null;
}

async function lines(pi: ExtensionAPI, args: string[]): Promise<string[]> {
	const { stdout, stderr, code } = await git(pi, args);
	if (code !== 0) throw new Error(`git ${args.join(" ")} failed: ${stderr.trim() || stdout.trim()}`);
	return stdout.trim() ? stdout.trim().split("\n") : [];
}

async function conflictedFiles(pi: ExtensionAPI): Promise<string[]> {
	const { stdout, code } = await git(pi, ["diff", "--name-only", "--diff-filter=U"]);
	if (code !== 0 || !stdout.trim()) return [];
	return stdout.trim().split("\n");
}

export default function gitBranchBehind(pi: ExtensionAPI) {
	pi.registerCommand("branch-behind", {
		description: "Restore branch ancestry: merge <target> into <source> on a throwaway branch (no push)",
		handler: async (raw, ctx: ExtensionCommandContext) => {
			const parsed = parseArgs(raw);
			if ("error" in parsed) {
				ctx.ui.notify(parsed.error, "error");
				return;
			}

			const { code: repoCode } = await git(pi, ["rev-parse", "--git-dir"]);
			if (repoCode !== 0) {
				ctx.ui.notify("Not a git repository", "error");
				return;
			}

			let { source, target } = parsed;
			const { remote } = parsed;

			if (!source) {
				source = (await ctx.ui.editor("Source branch (the MR source, e.g. develop):", "develop"))?.trim() ?? "";
			}
			if (!target) {
				target = (await ctx.ui.editor("Target branch (the MR target, e.g. main):", "main"))?.trim() ?? "";
			}
			if (!source || !target) {
				ctx.ui.notify("Cancelled", "info");
				return;
			}
			if (source === target) {
				ctx.ui.notify("Source and target must differ.", "error");
				return;
			}

			const dirty = await requireClean(pi);
			if (dirty) {
				ctx.ui.notify(dirty, "error");
				return;
			}

			ctx.ui.notify(`Fetching ${remote}...`, "info");
			const { code: fetchCode, stderr: fetchErr } = await git(pi, ["fetch", remote]);
			if (fetchCode !== 0) {
				ctx.ui.notify(`git fetch ${remote} failed: ${fetchErr.trim()}`, "error");
				return;
			}

			const srcRef = `${remote}/${source}`;
			const tgtRef = `${remote}/${target}`;
			for (const ref of [srcRef, tgtRef]) {
				const { code } = await git(pi, ["rev-parse", "--verify", `refs/remotes/${ref}`]);
				if (code !== 0) {
					ctx.ui.notify(`Ref '${ref}' does not exist.`, "error");
					return;
				}
			}

			let behind: string[];
			let missingContent: string[];
			try {
				behind = await lines(pi, ["log", "--oneline", `${srcRef}..${tgtRef}`]);
				missingContent = await lines(pi, [
					"log",
					"--oneline",
					"--no-merges",
					"--cherry-pick",
					"--right-only",
					`${srcRef}...${tgtRef}`,
				]);
			} catch (e) {
				ctx.ui.notify(e instanceof Error ? e.message : String(e), "error");
				return;
			}

			if (behind.length === 0) {
				ctx.ui.notify(`${srcRef} is not behind ${tgtRef}; nothing to do.`, "info");
				return;
			}

			const ancestryOnly = missingContent.length === 0;
			const branch = `chore/ancestry-${target}-into-${source}`;

			const { code: existsCode } = await git(pi, ["rev-parse", "--verify", `refs/heads/${branch}`]);
			if (existsCode === 0) {
				ctx.ui.notify(`Local branch '${branch}' already exists. Delete it (git branch -D ${branch}) and retry.`, "error");
				return;
			}

			const { stderr: coErr, code: coCode } = await git(pi, ["checkout", "-b", branch, srcRef]);
			if (coCode !== 0) {
				ctx.ui.notify(`Failed to create ${branch}: ${coErr.trim()}`, "error");
				return;
			}

			const message = `chore: merge ${target} into ${source} (restore ancestry)`;
			const { code: mergeCode } = await git(pi, ["merge", "--no-ff", tgtRef, "-m", message]);

			if (mergeCode !== 0) {
				const conflicts = await conflictedFiles(pi);
				pi.sendUserMessage(
					[
						`Merging ${tgtRef} into ${srcRef} on branch \`${branch}\` produced conflicts:`,
						"",
						...conflicts.map((f) => `  ${f}`),
						"",
						`Resolve them. Rule: keep ${source}'s intentional changes, never drop ${target}-only work.`,
						"Do not push and do not open an MR; stop after committing the merge locally.",
					].join("\n"),
					{ deliverAs: "followUp" },
				);
				ctx.ui.notify(`Merge conflicts in ${conflicts.length} file(s); handed to the agent.`, "warning");
				return;
			}

			const { stdout: diff } = await git(pi, ["diff", "--stat", srcRef, "HEAD"]);
			const diffEmpty = diff.trim() === "";

			const report = [
				`Branch created: ${branch} (from ${srcRef})`,
				`Merge commit:   ${message}`,
				"",
				`${srcRef} is ${behind.length} commit(s) behind ${tgtRef}.`,
				ancestryOnly
					? "Case: ancestry only — all patches already exist in the source branch."
					: `Case: real content missing (${missingContent.length} commit(s)) — review the incoming diff.`,
				ancestryOnly && !diffEmpty
					? `WARNING: ancestry-only case but 'git diff ${srcRef} HEAD' is NOT empty. Review before pushing:\n${diff.trim()}`
					: diffEmpty
						? `Verified: 'git diff ${srcRef} HEAD' is empty.`
						: `Incoming diff:\n${diff.trim()}`,
				"",
				"Next steps (run yourself):",
				`  git push -u ${remote} ${branch}`,
				`  open an MR: ${branch} -> ${source}`,
				"  MR settings: merge commit, SQUASH OFF (squash destroys ancestry).",
				"",
				`After it merges, ${source} contains ${target} and the original MR reports 0 behind.`,
				"If a CI job syncs branches by cherry-picking, that is the root cause — it copies patches, not ancestry.",
			].join("\n");

			ctx.ui.notify(
				ancestryOnly && diffEmpty
					? `Ancestry merge ready on ${branch} (empty diff).`
					: `Merge ready on ${branch} — review the diff.`,
				ancestryOnly && diffEmpty ? "info" : "warning",
			);
			pi.sendUserMessage(report, { deliverAs: "followUp" });
		},
	});
}
