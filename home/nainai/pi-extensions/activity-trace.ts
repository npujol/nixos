import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { basename, join } from "node:path";
import { homedir } from "node:os";
import { pathToFileURL } from "node:url";

const CORE_PATH = process.env.PI_ACTIVITY_TRACE_CORE ?? join(homedir(), ".pi", "agent", "lib", "activity-trace-core.mjs");
const { ACTIVITY_TRACE_ROOT, getGitContext, makeEvent, writeEventWithNotification } = await import(pathToFileURL(CORE_PATH).href);

function sessionStartDate(ctx: ExtensionContext): string {
  const sessionFile = ctx.sessionManager.getSessionFile();
  const filenameDate = sessionFile ? basename(sessionFile).match(/^(\d{4}-\d{2}-\d{2})/)?.[1] : undefined;
  return filenameDate ?? new Date().toISOString().slice(0, 10);
}

export default function activityTraceExtension(pi: ExtensionAPI) {
  let startDate = new Date().toISOString().slice(0, 10);

  const record = async (
    type: "session_start" | "checkpoint" | "session_shutdown",
    ctx: ExtensionContext,
    entryId?: string,
  ) => {
    try {
      const sessionId = ctx.sessionManager.getSessionId();
      const event = makeEvent({
        type,
        sessionId,
        entryId,
        cwd: ctx.cwd,
        gitContext: getGitContext(ctx.cwd),
      });
      await writeEventWithNotification(event, {
        root: ACTIVITY_TRACE_ROOT,
        startDate,
        notify: (message) => ctx.ui.notify(message, "warning"),
      });
    } catch (error) {
      ctx.ui.notify(`Activity trace could not record ${type}: ${error instanceof Error ? error.message : String(error)}`, "warning");
    }
  };

  pi.on("session_start", async (_event, ctx) => {
    startDate = sessionStartDate(ctx);
    await record("session_start", ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    const entryId = ctx.sessionManager.getLeafId();
    if (!entryId) {
      ctx.ui.notify("Activity trace could not record checkpoint: Pi returned no leaf entry ID", "warning");
      return;
    }
    await record("checkpoint", ctx, entryId);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    await record("session_shutdown", ctx);
  });
}
