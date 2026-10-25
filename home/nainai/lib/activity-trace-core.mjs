import { appendFile, mkdir } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { homedir } from "node:os";
import { spawnSync } from "node:child_process";

export const ACTIVITY_TRACE_ROOT = process.env.PI_ACTIVITY_TRACE_ROOT ?? join(homedir(), ".pi", "agent", "activity-trace");
const EVENT_TYPES = new Set(["session_start", "checkpoint", "session_shutdown"]);

export function getGitContext(cwd, runGit = spawnSync) {
  const workingDirectory = resolve(cwd);
  const rootResult = runGit("git", ["-C", workingDirectory, "rev-parse", "--show-toplevel"], {
    encoding: "utf8",
  });
  if (rootResult.error || rootResult.status !== 0) {
    return {
      repoRoot: null,
      repo: null,
      branch: null,
      contextError: rootResult.error?.message ?? (rootResult.stderr || "not a git repository").trim(),
    };
  }

  const repoRoot = rootResult.stdout.trim();
  const branchResult = runGit("git", ["-C", repoRoot, "symbolic-ref", "--quiet", "--short", "HEAD"], {
    encoding: "utf8",
  });
  if (branchResult.error || branchResult.status !== 0 || !branchResult.stdout.trim()) {
    return {
      repoRoot,
      repo: basename(repoRoot),
      branch: null,
      contextError: branchResult.error?.message ?? "detached HEAD or branch unavailable",
    };
  }

  return {
    repoRoot,
    repo: basename(repoRoot),
    branch: branchResult.stdout.trim(),
    contextError: null,
  };
}

export function makeEvent({ type, sessionId, entryId = null, timestamp = new Date().toISOString(), cwd, gitContext }) {
  if (!EVENT_TYPES.has(type)) throw new TypeError(`Unsupported activity event type: ${type}`);
  if (typeof sessionId !== "string" || !sessionId.trim()) throw new TypeError("sessionId is required");
  if (type === "checkpoint" && (typeof entryId !== "string" || !entryId.trim())) {
    throw new TypeError("checkpoint entryId is required");
  }

  const context = gitContext ?? getGitContext(cwd);
  return {
    type,
    sessionId,
    ...(entryId ? { entryId } : {}),
    timestamp,
    cwd: resolve(cwd),
    repoRoot: context.repoRoot,
    repo: context.repo,
    branch: context.branch,
    contextError: context.contextError,
  };
}

export function eventFilePath(sessionId, startDate, root = ACTIVITY_TRACE_ROOT) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(startDate)) throw new TypeError("startDate must be YYYY-MM-DD");
  if (!/^[A-Za-z0-9_-]+$/.test(sessionId)) throw new TypeError("sessionId contains unsafe path characters");
  return join(root, startDate, `${sessionId}.jsonl`);
}

export async function appendEvent(event, { root = ACTIVITY_TRACE_ROOT, startDate = event.timestamp.slice(0, 10), fs = { mkdir, appendFile } } = {}) {
  const filePath = eventFilePath(event.sessionId, startDate, root);
  await fs.mkdir(dirname(filePath), { recursive: true });
  await fs.appendFile(filePath, `${JSON.stringify(event)}\n`, "utf8");
  return filePath;
}

export async function writeEventWithNotification(event, { notify, ...options }) {
  try {
    await appendEvent(event, options);
    return true;
  } catch (error) {
    notify(`Activity trace could not write ${event.type}: ${error instanceof Error ? error.message : String(error)}`);
    return false;
  }
}

export function parseEventLine(line) {
  const event = JSON.parse(line);
  if (!event || typeof event !== "object" || Array.isArray(event)) throw new TypeError("event must be an object");
  if (!EVENT_TYPES.has(event.type) || typeof event.sessionId !== "string" || typeof event.timestamp !== "string") {
    throw new TypeError("event is missing required fields");
  }
  if (event.type === "checkpoint" && typeof event.entryId !== "string") {
    throw new TypeError("checkpoint event is missing entryId");
  }
  return event;
}
