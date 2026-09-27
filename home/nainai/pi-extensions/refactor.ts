/**
 * Refactor Extension
 *
 * Provides a `/refactor` command that prompts the agent to refactor code
 * in a file or a directory of files.
 *
 * Usage:
 * - `/refactor` — show interactive selector
 * - `/refactor file src/foo/bar.ts` — refactor a single file
 * - `/refactor folder src/components` — refactor all files in a folder (recursive)
 * - `/refactor --mode cleanup` — specific refactoring mode
 * - `/refactor --mode extract` — extract functions/classes
 * - `/refactor --mode simplify` — simplify/flatten
 * - `/refactor --mode type` — improve types
 * - `/refactor --extra "remove all console.logs"` — extra instruction (any mode)
 *
 * Modes:
 * - cleanup — remove dead code, dead imports, redundant patterns
 * - extract — extract repeated logic into functions/classes
 * - simplify — flatten nesting, remove unnecessary complexity
 * - type — improve TypeScript types (narrow unions, add generics, remove `any`)
 * - custom — let the agent decide what needs refactoring
 *
 * Project-specific guidelines:
 * - If a REFACTOR_GUIDELINES.md file exists in the same directory as .pi,
 *   its contents are appended to the refactoring prompt.
 */

import type { ExtensionAPI, ExtensionContext, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { DynamicBorder, BorderedLoader } from "@earendil-works/pi-coding-agent";
import { Container, fuzzyFilter, Input, type SelectItem, SelectList, Spacer, Text } from "@earendil-works/pi-tui";
import path from "node:path";
import { promises as fs } from "node:fs";

// ── State ──────────────────────────────────────────────────────────────────

let refactorOriginId: string | undefined = undefined;
let endRefactorInProgress = false;
let refactorLoopFixingEnabled = false;
let refactorCustomInstructions: string | undefined = undefined;
let refactorLoopInProgress = false;

const REFACTOR_STATE_TYPE = "refactor-session";
const REFACTOR_ANCHOR_TYPE = "refactor-anchor";
const REFACTOR_SETTINGS_TYPE = "refactor-settings";
const REFACTOR_LOOP_MAX_ITERATIONS = 10;
const REFACTOR_LOOP_START_TIMEOUT_MS = 15000;
const REFACTOR_LOOP_START_POLL_MS = 50;

type RefactorSessionState = { active: boolean; originId?: string };
type RefactorSettingsState = { loopFixingEnabled?: boolean; customInstructions?: string };

// ── UI helpers ─────────────────────────────────────────────────────────────

function setRefactorWidget(ctx: ExtensionContext, active: boolean) {
  if (!ctx.hasUI) return;
  if (!active) { ctx.ui.setWidget("refactor", undefined); return; }
  ctx.ui.setWidget("refactor", (_tui, theme) => {
    const msg = refactorLoopInProgress
      ? "Refactor session active (loop fixing running)"
      : refactorLoopFixingEnabled
        ? "Refactor session active (loop fixing enabled), return with /end-refactor"
        : "Refactor session active, return with /end-refactor";
    const text = new Text(theme.fg("warning", msg), 0, 0);
    return {
      render(width: number) { return text.render(width); },
      invalidate() { text.invalidate(); },
    };
  });
}

function getRefactorState(ctx: ExtensionContext): RefactorSessionState | undefined {
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type === "custom" && entry.customType === REFACTOR_STATE_TYPE) return entry.data as RefactorSessionState | undefined;
  }
  return undefined;
}

function applyRefactorState(ctx: ExtensionContext) {
  const state = getRefactorState(ctx);
  if (state?.active && state.originId) { refactorOriginId = state.originId; setRefactorWidget(ctx, true); return; }
  refactorOriginId = undefined;
  setRefactorWidget(ctx, false);
}

function isRefactorSettingsState(obj: unknown): obj is RefactorSettingsState {
  // Validate shape: check that expected fields, if present, have correct types.
  if (!obj || typeof obj !== "object") return false;
  const o = obj as Record<string, unknown>;
  if (o.loopFixingEnabled !== undefined && typeof o.loopFixingEnabled !== "boolean") return false;
  if (o.customInstructions !== undefined && typeof o.customInstructions !== "string") return false;
  return true;
}

function getRefactorSettings(ctx: ExtensionContext): RefactorSettingsState {
  let state: RefactorSettingsState | undefined;
  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "custom" && entry.customType === REFACTOR_SETTINGS_TYPE) {
      // Validate shape before casting persisted state
      if (isRefactorSettingsState(entry.data)) {
        state = entry.data;
      } else {
        console.warn("[refactor] getRefactorSettings: persisted settings have unexpected shape, ignoring");
      }
    }
  }
  return {
    loopFixingEnabled: state?.loopFixingEnabled === true,
    customInstructions: state?.customInstructions?.trim() || undefined,
  };
}

function applyRefactorSettings(ctx: ExtensionContext) {
  const state = getRefactorSettings(ctx);
  refactorLoopFixingEnabled = state.loopFixingEnabled === true;
  refactorCustomInstructions = state.customInstructions?.trim() || undefined;
}

function applyAllRefactorState(ctx: ExtensionContext) {
  applyRefactorSettings(ctx);
  applyRefactorState(ctx);
}

// ── Loop detection helpers ─────────────────────────────────────────────────

type AssistantSnapshot = {
  id: string;
  text: string;
  stopReason?: string;
};

function extractAssistantTextContent(content: unknown): string {
  if (typeof content === "string") {
    return content.trim();
  }
  if (!Array.isArray(content)) {
    // Unexpected content shape: not string, not array
    console.warn("[refactor] extractAssistantTextContent: expected string or array, got", typeof content);
    return "";
  }
  const textParts = content
    .filter(
      (part): part is { type: "text"; text: string } =>
        Boolean(part && typeof part === "object" && "type" in part && part.type === "text" && "text" in part),
    )
    .map((part) => part.text);
  if (content.length > 0 && textParts.length === 0) {
    // Array had items but none matched expected shape
    console.warn("[refactor] extractAssistantTextContent: array had items but no text parts found");
  }
  return textParts.join("\n").trim();
}

function getLastAssistantSnapshot(ctx: ExtensionContext): AssistantSnapshot | null {
  const entries = ctx.sessionManager.getBranch();
  for (let i = entries.length - 1; i >= 0; i--) {
    const entry = entries[i];
    if (entry.type !== "message" || entry.message.role !== "assistant") {
      continue;
    }
    const assistantMessage = entry.message as { content?: unknown; stopReason?: string };
    return {
      id: entry.id,
      text: extractAssistantTextContent(assistantMessage.content),
      stopReason: assistantMessage.stopReason,
    };
  }
  return null;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForLoopTurnToStart(ctx: ExtensionContext, previousAssistantId?: string): Promise<boolean> {
  // Poll until a new assistant message appears (confirmed by changed ID) or timeout occurs.
  // This detects when the agent has started responding to the refactor prompt.
  const deadline = Date.now() + REFACTOR_LOOP_START_TIMEOUT_MS;
  while (Date.now() < deadline) {
    const lastAssistantId = getLastAssistantSnapshot(ctx)?.id;
    // New assistant message detected: ID changed from previous baseline
    if (lastAssistantId && lastAssistantId !== previousAssistantId) {
      return true;
    }
    await sleep(REFACTOR_LOOP_START_POLL_MS);
  }
  // Timeout: no new assistant message appeared within the deadline
  return false;
}

function isLikelyRefactorFinding(line: string): boolean {
  // Look for priority tags or explicit finding markers
  if (/\[(P[0-3]|finding|issue|change|suggestion)\]/i.test(line)) {
    return true;
  }
  if (/^\s*(?:[-*+]|(?:\d+)[.)])\s+/.test(line) && /\b(refactor|change|improve|fix|replace|update|remove|add|extract|consolidate)\b/i.test(line)) {
    return true;
  }
  return false;
}

function hasBlockingRefactorFindings(messageText: string): boolean {
  const lines = messageText.split(/\r?\n/);
  let foundTaggedFinding = false;
  for (const line of lines) {
    if (/^\s*```/.test(line)) continue;
    if (!isLikelyRefactorFinding(line)) continue;
    foundTaggedFinding = true;
    // P0/P1 findings are always blocking
    if (/\[(P0|P1)\]/i.test(line)) {
      return true;
    }
  }
  // Check if the response explicitly says no changes needed (negates findings)
  if (/\b(no changes needed|looks good|no refactoring needed|code is fine)\b/i.test(messageText)) {
    return false;
  }
  // If we found findings and they're not negated by "no changes needed", they are blocking
  if (foundTaggedFinding) {
    return true;
  }
  // No findings found
  return false;
}

// ── Smart defaults ──────────────────────────────────────────────────────────

async function getSmartDefaultMode(pi: ExtensionAPI, cwd: string): Promise<RefactorMode> {
  // Check for common patterns that suggest specific modes
  try {
    const { stdout, code } = await pi.exec("git", ["diff", "--cached", "--stat"]);
    if (code === 0 && stdout.trim()) {
      // If there are staged changes, default to cleanup (review what's staged)
      return "cleanup";
    }
  } catch (error) {
    // Expected: git may not be available or not a git repo. Log and continue to next check.
    if (error instanceof Error) {
      console.debug("[refactor] git diff check failed:", error.message);
    }
  }

  // Check for files with console.log (suggests cleanup)
  try {
    const { stdout: consoleFiles, code: consoleCode } = await pi.exec("grep", ["-r", "--include=*.ts", "--include=*.tsx", "console\\.log", cwd]);
    if (consoleCode === 0) {
      return "cleanup";
    }
  } catch (error) {
    // Expected: grep may not be available or may fail on large trees. Log and continue to fallback.
    if (error instanceof Error) {
      console.debug("[refactor] grep console.log check failed:", error.message);
    }
  }

  // Default to custom (let agent decide)
  return "custom";
}

// ── Refactoring guidelines ─────────────────────────────────────────────────

const REFACTORING_GUIDELINES = `# Refactoring Guidelines

You are acting as a code reviewer for a proposed code change made by another engineer. 

Below are default guidelines for determining what to flag. These are not the final word — if you encounter more specific guidelines elsewhere (in a developer message, user message, file, or project review guidelines appended below, PATTERN files), those override these general instructions.

## General principles

1. Preserve behavior - identical output for all inputs.
2. Small, incremental changes - group related changes.
3. Respect existing patterns - prefer consistency over introducing "better" ones.
4. No new dependencies -  unless explicitly requested.
5. Keep imports clean — remove unused, group logically.
6. Small functions with scoped behavior.
7. Minimum of comment - not what only why.

## Refactoring modes

### cleanup
- Remove dead code (unused variables, imports and functions)
- Remove commented-out code blocks
- Consolidate redundant null/undefined checks
- Remove redundant type assertions (as, any, unknown) - use specific instead
- Replace repetitive conditionals with early returns or guard clauses

### extract
- Extract repeated code blocks into functions
- Extract repeated object creation into factory functions
- Extract magic strings/numbers into named constants - use specific files for the constants
- Extract complex expressions into descriptive variables
- Extract classes with shared responsibilities into smaller units

### simplify
- Flatten deeply nested conditionals (guard clause pattern)
- Replace complex boolean expressions with named variables
- Replace switch statements with lookup maps where appropriate
- Remove unnecessary try/catch wrappers
- Simplify overly complex type aliases or union types

### type
- Narrow overly broad types (any → specific type, unknown → guarded)
- Add proper generics to reusable functions
- Replace string literal unions with proper enum-like patterns
- Improve return types (never for functions that always throw)
- Add readonly where mutation is unnecessary
- Remove redundant type annotations the compiler can infer

### custom
- Agent decides what refactoring is needed based on code quality analysis
- Focus on the most impactful improvements first

## Output requirements

1. Show the diff or full file content for each changed file.
2. Briefly explain what was changed and why.
3. If a change might affect behavior, flag it explicitly.
4. List files that were NOT changed and why.

## After findings/verdict, you MUST append this final section:
Human Reviewer Callouts (Non-Blocking)

Include only applicable callouts (no yes/no lines):
- This change adds a database migration: <files/details>
- This change introduces a new dependency: <package(s)/details>
- This change changes a dependency (or the lockfile): <files/package(s)/details>
- This change modifies auth/permission behavior: <what changed and where>
- This change introduces backwards-incompatible public schema/API/contract changes: <what changed and where>
- This change includes irreversible or destructive operations: <operation and scope>
- This change includes new environments variable: <what changed and where>

Rules for this section:
1. These are informational callouts for the human reviewer, not fix items.
2. Do not include them in Findings unless there is an independent defect.
3. These callouts alone must not change the verdict.
4. Only include callouts that apply to the reviewed change.
5. Keep each emitted callout bold exactly as written.
6. If none apply, write "- (none)".
`;

type RefactorMode = "cleanup" | "extract" | "simplify" | "type" | "custom";

const REFACTOR_MODES: { value: RefactorMode; label: string; description: string }[] = [
  { value: "cleanup", label: "Cleanup", description: "Remove dead code, unused imports, redundant patterns" },
  { value: "extract", label: "Extract", description: "Extract functions, constants, classes" },
  { value: "simplify", label: "Simplify", description: "Flatten nesting, remove complexity" },
  { value: "type", label: "Improve types", description: "Narrow types, add generics, remove any" },
  { value: "custom", label: "Custom", description: "Agent decides what needs refactoring" },
];

type RefactorTarget =
  | { type: "file"; filePath: string }
  | { type: "folder"; folderPath: string };

// ── File/folder helpers ────────────────────────────────────────────────────

const SKIP_DIRS = new Set(["node_modules",".git","dist","build",".next","__pycache__",".pi",".nix-darwin",".venv","venv",".tox",".mypy_cache",".pytest_cache",".eslintcache",".DS_Store",".pnpm-store",".svelte-kit",".output",".nuxt"]);
const SCAN_EXTS = new Set([".ts",".tsx",".js",".jsx",".mjs",".cjs",".py",".pyi",".rs",".go",".java",".c",".cpp",".h",".hpp",".rb",".lua",".php",".swift",".kt",".scala",".sh",".bash",".zsh",".md",".txt",".rst",".yaml",".yml",".toml",".json",".xml",".css",".scss",".sass",".less",".sql",".vue",".svelte",".astro"]);

async function findSourceFiles(dir: string): Promise<string[]> {
  const results: string[] = [];
  let entries: fs.Dirent[];
  try { entries = await fs.readdir(dir, { withFileTypes: true }); } catch { return results; }
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) { if (SKIP_DIRS.has(entry.name)) continue; results.push(...(await findSourceFiles(fullPath))); }
    else if (entry.isFile() && SCAN_EXTS.has(path.extname(entry.name).toLowerCase())) { results.push(fullPath); }
  }
  return results;
}

async function buildRefactorPrompt(target: RefactorTarget, mode: RefactorMode): Promise<string> {
  const modeInfo = REFACTOR_MODES.find((m) => m.value === mode);
  const modeDesc = modeInfo ? `${mode.value} mode — ${modeInfo.description}` : mode.value;
  switch (target.type) {
    case "file":
      return `Refactor the file "${target.filePath}" using the ${modeDesc} approach. Read the file, analyze for refactoring opportunities, and apply improvements while preserving external behavior.`;
    case "folder":
      return `Refactor all source files in "${target.folderPath}" recursively using the ${modeDesc} approach. Find all source files, analyze each, and apply improvements one at a time while preserving external behavior.`;
  }
}

async function loadProjectRefactorGuidelines(cwd: string): Promise<string | null> {
  let currentDir = path.resolve(cwd);
  while (true) {
    const piDir = path.join(currentDir, ".pi");
    const gp = path.join(currentDir, "REFACTOR_GUIDELINES.md");
    const piStats = await fs.stat(piDir).catch(() => null);
    if (piStats?.isDirectory()) {
      const gs = await fs.stat(gp).catch(() => null);
      if (gs?.isFile()) {
        try { const c = (await fs.readFile(gp, "utf8")).trim(); if (c) return c; } catch { /* */ }
      }
      return null;
    }
    const parent = path.dirname(currentDir);
    if (parent === currentDir) return null;
    currentDir = parent;
  }
}

// ── Selector: file ─────────────────────────────────────────────────────────

async function showFileSelector(ctx: ExtensionContext, cwd: string): Promise<string | null> {
  const files = await findSourceFiles(cwd);
  if (files.length === 0) { ctx.ui.notify("No source files found.", "error"); return null; }
  const items: SelectItem[] = files.map((f) => ({ value: f, label: path.relative(cwd, f), description: "" }));

  return ctx.ui.custom<string | null>((tui, theme, keybindings, done) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
    container.addChild(new Text(theme.fg("accent", theme.bold("Select file to refactor"))));
    const searchInput = new Input();
    container.addChild(searchInput);
    container.addChild(new Spacer(1));
    const listContainer = new Container();
    container.addChild(listContainer);
    container.addChild(new Text(theme.fg("dim", "Type to filter • enter to select • esc to cancel")));
    container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));

    let filteredItems = items;
    let selectList: SelectList | null = null;

    const updateList = () => {
      listContainer.clear();
      if (filteredItems.length === 0) { listContainer.addChild(new Text(theme.fg("warning", "  No matching files"))); selectList = null; return; }
      selectList = new SelectList(filteredItems, Math.min(filteredItems.length, 10), {
        selectedPrefix: (t) => theme.fg("accent", t), selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t), scrollInfo: (t) => theme.fg("dim", t), noMatch: (t) => theme.fg("warning", t),
      });
      selectList.onSelect = (item) => done(item.value);
      selectList.onCancel = () => done(null);
      listContainer.addChild(selectList);
    };

    const applyFilter = () => {
      const q = searchInput.getValue();
      filteredItems = q ? fuzzyFilter(items, q, (item) => `${item.label} ${item.value}`) : items;
      updateList();
    };

    applyFilter();

    return {
      render(w: number) { return container.render(w); },
      invalidate() { container.invalidate(); },
      handleInput(data: string) {
        if (keybindings.matches(data, "tui.select.up") || keybindings.matches(data, "tui.select.down")
            || keybindings.matches(data, "tui.select.confirm") || keybindings.matches(data, "tui.select.cancel")) {
          if (selectList) { selectList.handleInput(data); }
          else if (keybindings.matches(data, "tui.select.cancel")) { done(null); }
          tui.requestRender(); return;
        }
        searchInput.handleInput(data); applyFilter(); tui.requestRender();
      },
    };
  });
}

// ── Selector: folder ───────────────────────────────────────────────────────

async function showFolderSelector(ctx: ExtensionContext, cwd: string): Promise<string | null> {
  const files = await findSourceFiles(cwd);
  if (files.length === 0) { ctx.ui.notify("No source files found.", "error"); return null; }
  const folderSet = new Set<string>();
  for (const file of files) { const p = path.dirname(file); if (p !== cwd) folderSet.add(p); }
  const folders = Array.from(folderSet).sort();
  if (folders.length === 0) { ctx.ui.notify("No subfolders with source files found.", "error"); return null; }

  const items: SelectItem[] = folders.map((f) => ({ value: f, label: path.relative(cwd, f), description: "" }));

  return ctx.ui.custom<string | null>((tui, theme, keybindings, done) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
    container.addChild(new Text(theme.fg("accent", theme.bold("Select folder to refactor"))));
    const searchInput = new Input();
    container.addChild(searchInput);
    container.addChild(new Spacer(1));
    const listContainer = new Container();
    container.addChild(listContainer);
    container.addChild(new Text(theme.fg("dim", "Type to filter • enter to select • esc to cancel")));
    container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));

    let filteredItems = items;
    let selectList: SelectList | null = null;

    const updateList = () => {
      listContainer.clear();
      if (filteredItems.length === 0) { listContainer.addChild(new Text(theme.fg("warning", "  No matching folders"))); selectList = null; return; }
      selectList = new SelectList(filteredItems, Math.min(filteredItems.length, 10), {
        selectedPrefix: (t) => theme.fg("accent", t), selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t), scrollInfo: (t) => theme.fg("dim", t), noMatch: (t) => theme.fg("warning", t),
      });
      selectList.onSelect = (item) => done(item.value);
      selectList.onCancel = () => done(null);
      listContainer.addChild(selectList);
    };

    const applyFilter = () => {
      const q = searchInput.getValue();
      filteredItems = q ? fuzzyFilter(items, q, (item) => `${item.label} ${item.value}`) : items;
      updateList();
    };

    applyFilter();

    return {
      render(w: number) { return container.render(w); },
      invalidate() { container.invalidate(); },
      handleInput(data: string) {
        if (keybindings.matches(data, "tui.select.up") || keybindings.matches(data, "tui.select.down")
            || keybindings.matches(data, "tui.select.confirm") || keybindings.matches(data, "tui.select.cancel")) {
          if (selectList) { selectList.handleInput(data); }
          else if (keybindings.matches(data, "tui.select.cancel")) { done(null); }
          tui.requestRender(); return;
        }
        searchInput.handleInput(data); applyFilter(); tui.requestRender();
      },
    };
  });
}

// ── Selector: mode ─────────────────────────────────────────────────────────

const TOGGLE_LOOP_FIXING_VALUE = "toggleLoopFixing" as const;
const TOGGLE_CUSTOM_INSTRUCTIONS_VALUE = "toggleCustomInstructions" as const;
type RefactorSelectorValue = RefactorMode | typeof TOGGLE_LOOP_FIXING_VALUE | typeof TOGGLE_CUSTOM_INSTRUCTIONS_VALUE;

async function showModeSelector(ctx: ExtensionContext, smartDefault?: RefactorMode): Promise<RefactorMode> {
  const items: SelectItem[] = REFACTOR_MODES.map((m) => ({ value: m.value, label: m.label, description: m.description }));
  const smartDefaultIndex = smartDefault ? items.findIndex((m) => m.value === smartDefault) : -1;

  while (true) {
    const customInstructionsLabel = refactorCustomInstructions
      ? "Remove custom refactoring instructions"
      : "Add custom refactoring instructions";
    const customInstructionsDescription = refactorCustomInstructions
      ? "(currently set)"
      : "(applies to all refactor modes)";
    const loopToggleLabel = refactorLoopFixingEnabled ? "Disable Loop Fixing" : "Enable Loop Fixing";
    const loopToggleDescription = refactorLoopFixingEnabled ? "(currently on)" : "(currently off)";
    const allItems: SelectItem[] = [
      ...items,
      {
        value: TOGGLE_CUSTOM_INSTRUCTIONS_VALUE,
        label: customInstructionsLabel,
        description: customInstructionsDescription,
      },
      { value: TOGGLE_LOOP_FIXING_VALUE, label: loopToggleLabel, description: loopToggleDescription },
    ];

    const result = await ctx.ui.custom<RefactorSelectorValue | null>((tui, theme, _kb, done) => {
      const container = new Container();
      container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
      container.addChild(new Text(theme.fg("accent", theme.bold("Select refactoring mode"))));
      const selectList = new SelectList(allItems, Math.min(allItems.length, 10), {
        selectedPrefix: (t) => theme.fg("accent", t), selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t), scrollInfo: (t) => theme.fg("dim", t), noMatch: (t) => theme.fg("warning", t),
      });
      if (smartDefaultIndex >= 0) {
        selectList.setSelectedIndex(smartDefaultIndex);
      }
      selectList.onSelect = (item) => done(item.value as RefactorSelectorValue);
      selectList.onCancel = () => done(null);
      container.addChild(selectList);
      container.addChild(new Text(theme.fg("dim", "Press enter to confirm or esc to go back")));
      container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
      return { render: (w) => container.render(w), invalidate: () => container.invalidate(), handleInput: () => {} };
    });

    if (!result) return "custom";

    if (result === TOGGLE_LOOP_FIXING_VALUE) {
      const nextEnabled = !refactorLoopFixingEnabled;
      setRefactorLoopFixingEnabled(nextEnabled);
      ctx.ui.notify(nextEnabled ? "Loop fixing enabled" : "Loop fixing disabled", "info");
      continue;
    }

    if (result === TOGGLE_CUSTOM_INSTRUCTIONS_VALUE) {
      if (refactorCustomInstructions) {
        setRefactorCustomInstructions(undefined);
        ctx.ui.notify("Custom refactoring instructions removed", "info");
        continue;
      }
      const customInstructions = await ctx.ui.editor(
        "Enter custom refactoring instructions (applies to all refactor modes):",
        "",
      );
      if (!customInstructions?.trim()) {
        ctx.ui.notify("Custom refactoring instructions not changed", "info");
        continue;
      }
      setRefactorCustomInstructions(customInstructions);
      ctx.ui.notify("Custom refactoring instructions saved", "info");
      continue;
    }

    return result;
  }
}

// ── Execute refactor ───────────────────────────────────────────────────────

async function executeRefactor(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  target: RefactorTarget,
  mode: RefactorMode,
  useFreshSession: boolean,
  options?: { extraInstruction?: string },
): Promise<boolean> {
  if (refactorOriginId) {
    ctx.ui.notify("Already in a refactor. Use /end-refactor to finish first.", "warning");
    return false;
  }

  if (useFreshSession) {
    let originId = ctx.sessionManager.getLeafId() ?? undefined;
    if (!originId) {
      pi.appendEntry(REFACTOR_ANCHOR_TYPE, { createdAt: new Date().toISOString() });
      originId = ctx.sessionManager.getLeafId() ?? undefined;
    }
    if (!originId) { ctx.ui.notify("Failed to determine refactor origin.", "error"); return false; }
    refactorOriginId = originId;
    const lockedOriginId = originId;

    const entries = ctx.sessionManager.getEntries();
    const firstUserMessage = entries.find((e) => e.type === "message" && e.message.role === "user");
    if (firstUserMessage) {
      try {
        const result = await ctx.navigateTree(firstUserMessage.id, { summarize: false, label: "code-refactor" });
        if (result.cancelled) { refactorOriginId = undefined; return false; }
      } catch (error) {
        refactorOriginId = undefined;
        ctx.ui.notify(`Failed to start refactor: ${error instanceof Error ? error.message : String(error)}`, "error");
        return false;
      }
      ctx.ui.setEditorText("");
    }
    refactorOriginId = lockedOriginId;
    setRefactorWidget(ctx, true);
    pi.appendEntry(REFACTOR_STATE_TYPE, { active: true, originId: lockedOriginId });
  }

  const prompt = await buildRefactorPrompt(target, mode);
  const projectGuidelines = await loadProjectRefactorGuidelines(ctx.cwd);

  let fullPrompt = `${REFACTORING_GUIDELINES}\n\n---\n\n${prompt}`;

  if (refactorCustomInstructions) {
    fullPrompt += `\n\nShared custom refactoring instructions (applies to all refactors):\n\n${refactorCustomInstructions}`;
  }
  if (options?.extraInstruction?.trim()) {
    fullPrompt += `\n\nAdditional user-provided refactoring instruction:\n\n${options.extraInstruction.trim()}`;
  }
  if (projectGuidelines) {
    fullPrompt += `\n\nThis project has additional instructions for refactoring:\n\n${projectGuidelines}`;
  }

  const modeHint = useFreshSession ? " (fresh session)" : "";
  const hint = target.type === "file" ? target.filePath : target.folderPath;
  ctx.ui.notify(`Starting refactor: ${hint} [${mode}]${modeHint}`, "info");

  pi.sendUserMessage(fullPrompt);
  return true;
}

// ── Arg parsing ────────────────────────────────────────────────────────────

function tokenizeArgs(value: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let quote: '"' | "'" | null = null;
  for (let i = 0; i < value.length; i++) {
    const char = value[i];
    if (quote) {
      if (char === "\\" && i + 1 < value.length) { current += value[i + 1]; i++; continue; }
      if (char === quote) { quote = null; continue; }
      current += char; continue;
    }
    if (char === '"' || char === "'") { quote = char; continue; }
    if (/\s/.test(char)) { if (current.length > 0) { tokens.push(current); current = ""; } continue; }
    current += char;
  }
  if (current.length > 0) tokens.push(current);
  return tokens;
}

type ParsedRefactorArgs = { target: RefactorTarget | null; mode: RefactorMode; extraInstruction?: string };

function parseArgs(args: string | undefined): ParsedRefactorArgs {
  if (!args?.trim()) return { target: null, mode: "custom" };
  const rawParts = tokenizeArgs(args.trim());
  const parts: string[] = [];
  let extraInstruction: string | undefined;
  let mode: RefactorMode = "custom";

  for (let i = 0; i < rawParts.length; i++) {
    const part = rawParts[i];
    if (part === "--mode") {
      const next = rawParts[i + 1];
      if (next && ("cleanup|extract|simplify|type|custom".includes(next))) { mode = next as RefactorMode; i++; continue; }
      return { target: null, mode: "custom", error: `Invalid mode: ${next}` };
    }
    if (part === "--extra") {
      const next = rawParts[i + 1];
      if (!next) return { target: null, mode: "custom", error: "Missing value for --extra" };
      extraInstruction = next; i++; continue;
    }
    if (part.startsWith("--extra=")) { extraInstruction = part.slice("--extra=".length); continue; }
    parts.push(part);
  }

  if (parts.length === 0) return { target: null, mode, extraInstruction };

  const subcommand = parts[0]?.toLowerCase();
  switch (subcommand) {
    case "file": {
      const filePath = parts[1];
      if (!filePath) return { target: null, mode, extraInstruction };
      return { target: { type: "file", filePath: path.resolve(process.cwd(), filePath) }, mode, extraInstruction };
    }
    case "folder": {
      const folderPath = parts[1];
      if (!folderPath) return { target: null, mode, extraInstruction };
      return { target: { type: "folder", folderPath: path.resolve(process.cwd(), folderPath) }, mode, extraInstruction };
    }
    default:
      return { target: null, mode, extraInstruction };
  }
}

// ── Extension factory ──────────────────────────────────────────────────────

export default function refactorExtension(pi: ExtensionAPI) {
  function persistRefactorSettings() {
    pi.appendEntry(REFACTOR_SETTINGS_TYPE, {
      loopFixingEnabled: refactorLoopFixingEnabled,
      customInstructions: refactorCustomInstructions,
    });
  }

  function setRefactorLoopFixingEnabled(enabled: boolean) {
    refactorLoopFixingEnabled = enabled;
    persistRefactorSettings();
  }

  function setRefactorCustomInstructions(instructions: string | undefined) {
    refactorCustomInstructions = instructions?.trim() || undefined;
    persistRefactorSettings();
  }

  pi.on("session_start", (_event, ctx) => { applyAllRefactorState(ctx); });
  pi.on("session_tree", (_event, ctx) => { applyAllRefactorState(ctx); });

  pi.registerCommand("refactor", {
    description: "Refactor code in a file or folder",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) { ctx.ui.notify("Refactor requires interactive mode", "error"); return; }
      if (refactorLoopInProgress) { ctx.ui.notify("Refactor loop fixing is already running.", "warning"); return; }
      if (refactorOriginId) { ctx.ui.notify("Already in a refactor. Use /end-refactor to finish first.", "warning"); return; }

      const { code } = await pi.exec("git", ["rev-parse", "--git-dir"]);
      if (code !== 0) { ctx.ui.notify("Not a git repository", "error"); return; }

      const parsed = parseArgs(args);
      if (parsed.error) { ctx.ui.notify(parsed.error, "error"); return; }

      let target: RefactorTarget | null = parsed.target;
      let mode = parsed.mode;
      let extraInstruction = parsed.extraInstruction;

      // Show selectors if needed
      if (!target) {
        const choice = await ctx.ui.select("Refactor:", ["File", "Folder"]);
        if (!choice) { ctx.ui.notify("Refactor cancelled", "info"); return; }
        if (choice === "File") {
          target = { type: "file", filePath: (await showFileSelector(ctx, ctx.cwd)) ?? "" };
        } else {
          target = { type: "folder", folderPath: (await showFolderSelector(ctx, ctx.cwd)) ?? "" };
        }
        if (!target?.filePath && !target?.folderPath) { ctx.ui.notify("Refactor cancelled", "info"); return; }
      }

      // Get smart default mode if not explicitly set
      let smartDefaultMode: RefactorMode | undefined;
      if (!parsed.mode) {
        smartDefaultMode = await getSmartDefaultMode(pi, ctx.cwd);
      }

      if (!mode || mode === "custom") {
        if (!parsed.mode) {
          mode = await showModeSelector(ctx, smartDefaultMode);
        }
      }

      // Determine fresh session mode
      const entries = ctx.sessionManager.getEntries();
      const messageCount = entries.filter((e) => e.type === "message").length;
      let useFreshSession = messageCount === 0;

      if (messageCount > 0) {
        const choice = await ctx.ui.select("Start refactor in:", ["Empty branch", "Current session"]);
        if (!choice) { ctx.ui.notify("Refactor cancelled", "info"); return; }
        useFreshSession = choice === "Empty branch";
      }

      if (refactorLoopFixingEnabled) {
        await runLoopFixingRefactor(ctx, target, mode, extraInstruction);
        return;
      }

      await executeRefactor(pi, ctx, target, mode, useFreshSession, { extraInstruction });
    },
  });

  // ── Loop fixing refactor ───────────────────────────────────────────────

  async function runLoopFixingRefactor(
    ctx: ExtensionCommandContext,
    target: RefactorTarget | null,
    mode: RefactorMode,
    extraInstruction?: string,
  ): Promise<void> {
    if (!target) {
      ctx.ui.notify("Loop fixing requires a target (file or folder).", "error");
      return;
    }
    if (refactorLoopInProgress) {
      ctx.ui.notify("Loop fixing refactor is already running.", "warning");
      return;
    }

    refactorLoopInProgress = true;
    setRefactorWidget(ctx, Boolean(refactorOriginId));
    try {
      ctx.ui.notify(
        "Loop fixing enabled: using Empty branch mode and cycling until no blocking findings remain.",
        "info",
      );

      for (let pass = 1; pass <= REFACTOR_LOOP_MAX_ITERATIONS; pass++) {
        const refactorBaselineAssistantId = getLastAssistantSnapshot(ctx)?.id;
        const started = await executeRefactor(pi, ctx, target, mode, true, { extraInstruction });
        if (!started) {
          ctx.ui.notify("Loop fixing stopped before starting the refactor pass.", "warning");
          return;
        }

        const refactorTurnStarted = await waitForLoopTurnToStart(ctx, refactorBaselineAssistantId);
        if (!refactorTurnStarted) {
          ctx.ui.notify("Loop fixing stopped: refactor pass did not start in time.", "error");
          return;
        }

        await ctx.waitForIdle();

        const refactorSnapshot = getLastAssistantSnapshot(ctx);
        if (!refactorSnapshot || refactorSnapshot.id === refactorBaselineAssistantId) {
          ctx.ui.notify("Loop fixing stopped: could not read the refactor result.", "warning");
          return;
        }

        if (refactorSnapshot.stopReason === "aborted") {
          ctx.ui.notify("Loop fixing stopped: refactor was aborted.", "warning");
          return;
        }
        if (refactorSnapshot.stopReason === "error") {
          ctx.ui.notify("Loop fixing stopped: refactor failed with an error.", "error");
          return;
        }
        if (refactorSnapshot.stopReason === "length") {
          ctx.ui.notify("Loop fixing stopped: refactor output was truncated (stopReason=length).", "warning");
          return;
        }

        if (!hasBlockingRefactorFindings(refactorSnapshot.text)) {
          const finalized = await executeEndRefactorAction(ctx, "returnAndSummarize", {
            showSummaryLoader: true,
            notifySuccess: false,
          });
          if (finalized !== "ok") {
            return;
          }
          ctx.ui.notify("Loop fixing complete: no blocking findings remain.", "info");
          return;
        }

        ctx.ui.notify(`Loop fixing pass ${pass}: found blocking findings, returning to fix them...`, "info");

        const fixBaselineAssistantId = getLastAssistantSnapshot(ctx)?.id;
        const sentFixPrompt = await executeEndRefactorAction(ctx, "returnAndApply", {
          showSummaryLoader: true,
          notifySuccess: false,
        });
        if (sentFixPrompt !== "ok") {
          return;
        }

        const fixTurnStarted = await waitForLoopTurnToStart(ctx, fixBaselineAssistantId);
        if (!fixTurnStarted) {
          ctx.ui.notify("Loop fixing stopped: fix pass did not start in time.", "error");
          return;
        }

        await ctx.waitForIdle();

        const fixSnapshot = getLastAssistantSnapshot(ctx);
        if (!fixSnapshot || fixSnapshot.id === fixBaselineAssistantId) {
          ctx.ui.notify("Loop fixing stopped: could not read the fix pass result.", "warning");
          return;
        }
        if (fixSnapshot.stopReason === "aborted") {
          ctx.ui.notify("Loop fixing stopped: fix pass was aborted.", "warning");
          return;
        }
        if (fixSnapshot.stopReason === "error") {
          ctx.ui.notify("Loop fixing stopped: fix pass failed with an error.", "error");
          return;
        }
        if (fixSnapshot.stopReason === "length") {
          ctx.ui.notify("Loop fixing stopped: fix pass output was truncated (stopReason=length).", "warning");
          return;
        }
      }

      ctx.ui.notify(
        `Loop fixing stopped after ${REFACTOR_LOOP_MAX_ITERATIONS} passes (safety limit reached).`,
        "warning",
      );
    } finally {
      refactorLoopInProgress = false;
      setRefactorWidget(ctx, Boolean(refactorOriginId));
    }
  }

  // ── End refactor ───────────────────────────────────────────────────────

  const REFACTOR_SUMMARY_PROMPT = `We are leaving a code-refactor branch and returning to the main coding branch.
Create a structured handoff of the refactoring that was done.

Required sections:

## Refactor Scope
- What was refactored (files/paths)

## Changes Summary
For EACH file changed, include:
- File path
- What was changed (brief)
- Why it was changed

## Files Not Changed
- List files that were reviewed but not modified, with brief reason

## Verification Notes
- Any test results, lint results, or type-check results
- Known issues or areas that need manual verification

## Human Reviewer Callouts (Non-Blocking)
- **This change adds a database migration:** <files/details>
- **This change introduces a new dependency:** <package(s)/details>
- **This change changes a dependency (or the lockfile):** <files/package(s)/details>
- **This change modifies auth/permission behavior:** <what changed and where>
- **This change introduces backwards-incompatible public schema/API/contract changes:** <what changed and where>
- **This change includes irreversible or destructive operations:** <operation and scope>
If none apply, write "- (none)".

Preserve exact file paths, function names, and error messages where available.`;

  const REFACTOR_FIX_PROMPT = `Use the latest refactor summary in this session and implement the refactoring changes now.

Instructions:
1. Follow the changes described in the summary.
2. Apply each change carefully, preserving behavior.
3. Run relevant tests/checks for touched code where practical.
4. Report what was applied, what was skipped (with reasons), and verification results.`;

  type EndRefactorAction = "returnOnly" | "returnAndApply" | "returnAndSummarize";

  function getActiveRefactorOrigin(ctx: ExtensionContext): string | undefined {
    if (refactorOriginId) return refactorOriginId;
    const state = getRefactorState(ctx);
    if (state?.active && state.originId) { refactorOriginId = state.originId; return refactorOriginId; }
    if (state?.active) {
      setRefactorWidget(ctx, false);
      pi.appendEntry(REFACTOR_STATE_TYPE, { active: false });
      ctx.ui.notify("Refactor state was missing origin info; cleared.", "warning");
    }
    return undefined;
  }

  function clearRefactorState(ctx: ExtensionContext) {
    setRefactorWidget(ctx, false);
    refactorOriginId = undefined;
    pi.appendEntry(REFACTOR_STATE_TYPE, { active: false });
  }

  async function navigateWithRefactorSummary(
    ctx: ExtensionCommandContext,
    originId: string,
    showLoader: boolean,
  ): Promise<{ cancelled: boolean; error?: string } | null> {
    if (showLoader && ctx.hasUI) {
      return ctx.ui.custom<{ cancelled: boolean; error?: string } | null>((tui, theme, _kb, done) => {
        const loader = new BorderedLoader(tui, theme, "Returning and summarizing refactor branch...");
        loader.onAbort = () => done(null);
        ctx.navigateTree(originId, { summarize: true, customInstructions: REFACTOR_SUMMARY_PROMPT, replaceInstructions: true })
          .then(done)
          .catch((err) => done({ cancelled: false, error: err instanceof Error ? err.message : String(err) }));
        return loader;
      });
    }
    try {
      return await ctx.navigateTree(originId, { summarize: true, customInstructions: REFACTOR_SUMMARY_PROMPT, replaceInstructions: true });
    } catch (error) {
      return { cancelled: false, error: error instanceof Error ? error.message : String(error) };
    }
  }

  async function executeEndRefactorAction(
    ctx: ExtensionCommandContext,
    action: EndRefactorAction,
    options: { showSummaryLoader?: boolean; notifySuccess?: boolean } = {},
  ): Promise<"ok" | "cancelled" | "error"> {
    const originId = getActiveRefactorOrigin(ctx);
    if (!originId) {
      if (!getRefactorState(ctx)?.active) {
        ctx.ui.notify("Not in a refactor branch (use /refactor first, or started in current session mode)", "info");
      }
      return "error";
    }

    const notifySuccess = options.notifySuccess ?? true;

    if (action === "returnOnly") {
      try {
        const result = await ctx.navigateTree(originId, { summarize: false });
        if (result.cancelled) { ctx.ui.notify("Navigation cancelled. Use /end-refactor to try again.", "info"); return "cancelled"; }
      } catch (error) {
        ctx.ui.notify(`Failed to return: ${error instanceof Error ? error.message : String(error)}`, "error");
        return "error";
      }
      clearRefactorState(ctx);
      if (notifySuccess) ctx.ui.notify("Refactor complete! Returned to original position.", "info");
      return "ok";
    }

    const summaryResult = await navigateWithRefactorSummary(ctx, originId, options.showSummaryLoader ?? false);
    if (summaryResult === null) { ctx.ui.notify("Summarization cancelled. Use /end-refactor to try again.", "info"); return "cancelled"; }
    if (summaryResult.error) { ctx.ui.notify(`Summarization failed: ${summaryResult.error}`, "error"); return "error"; }
    if (summaryResult.cancelled) { ctx.ui.notify("Navigation cancelled. Use /end-refactor to try again.", "info"); return "cancelled"; }

    clearRefactorState(ctx);

    if (action === "returnAndSummarize") {
      if (!ctx.ui.getEditorText().trim()) ctx.ui.setEditorText("Apply the refactoring changes");
      if (notifySuccess) ctx.ui.notify("Refactor complete! Returned and summarized.", "info");
      return "ok";
    }

    pi.sendUserMessage(REFACTOR_FIX_PROMPT, { deliverAs: "followUp" });
    if (notifySuccess) ctx.ui.notify("Refactor complete! Returned and queued a follow-up to apply changes.", "info");
    return "ok";
  }

  async function runEndRefactor(ctx: ExtensionCommandContext): Promise<void> {
    if (!ctx.hasUI) { ctx.ui.notify("End-refactor requires interactive mode", "error"); return; }
    if (refactorLoopInProgress) { ctx.ui.notify("Refactor loop is running. Wait for it to finish.", "info"); return; }
    if (endRefactorInProgress) { ctx.ui.notify("/end-refactor is already running", "info"); return; }

    endRefactorInProgress = true;
    try {
      const choice = await ctx.ui.select("Finish refactor:", [
        "Return only",
        "Return and apply changes",
        "Return and summarize",
      ]);
      if (!choice) { ctx.ui.notify("Cancelled. Use /end-refactor to try again.", "info"); return; }

      const action: EndRefactorAction =
        choice === "Return and apply changes" ? "returnAndApply"
        : choice === "Return and summarize" ? "returnAndSummarize"
        : "returnOnly";

      await executeEndRefactorAction(ctx, action, { showSummaryLoader: true, notifySuccess: true });
    } finally {
      endRefactorInProgress = false;
    }
  }

  pi.registerCommand("end-refactor", {
    description: "Complete refactor and return to original position",
    handler: async (_args, ctx) => { await runEndRefactor(ctx); },
  });
}
