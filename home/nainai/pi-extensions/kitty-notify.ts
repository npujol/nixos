/**
 * Kitty Notification Extension
 * 
 * Sends a desktop notification via Kitty's OSC-99 protocol on macOS
 * every time Pi finishes processing a user command (only shows if kitty is not visible)
 * Ref: https://github.com/leiserfg/nix-config/blob/master/home/leiserfg/pi-extensions/kitty-notify.ts
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn } from "child_process";
import * as os from "os";

export default function (pi: ExtensionAPI) {
  const isMac = os.platform() === "darwin";

  /**
   * Send a notification using macOS native osascript (terminal-notifier fallback)
   */
  const sendMacNotification = (title: string, body: string) => {
    try {
      // Use osascript to trigger native macOS notifications
      const script = `display notification "${body.replace(/"/g, '\\"')}" with title "${title.replace(/"/g, '\\"')}"`;
      spawn("osascript", ["-e", script], {
        stdio: "ignore",
        detached: true,
      }).unref();
    } catch (error) {
      console.error("[kitty-notify] Failed to send macOS notification:", error);
    }
  };

  /**
   * Send a notification by writing directly to stdout (Kitty OSC-99)
   */
  const sendKittyNotification = (title: string, body: string) => {
    try {
      // Write OSC-99 notification directly to stdout
      // o=invisible: only show notification if window is not visible
      // On macOS, use osascript for more reliable notifications
      if (isMac) {
        sendMacNotification(title, body);
      } else {
        const notification = `\x1b]99;i=1:o=invisible;${title}: ${body}\x1b\\`;
        process.stdout.write(notification);
      }
    } catch (error) {
      console.error("[kitty-notify] Failed to send notification:", error);
    }
  };

  // Listen for when the agent finishes processing
  pi.on("agent_end", async (event, ctx) => {
    // Count tool calls in this turn
    const toolCount = event.messages.filter(
      (msg) => msg.role === "toolResult"
    ).length;

    // Get the session file name for context
    const sessionFile = ctx.sessionManager.getSessionFile();
    const sessionName = sessionFile 
      ? sessionFile.split('/').pop()?.replace('.pi.jsonl', '') 
      : 'ephemeral';

    // Send notification
    if (toolCount > 0) {
      sendKittyNotification(
        "Pi Task Complete",
        `Executed ${toolCount} tool${toolCount === 1 ? '' : 's'} in ${sessionName}`
      );
    } else {
      sendKittyNotification(
        "Pi Response Ready",
        `Response ready in ${sessionName}`
      );
    }
  });
}
