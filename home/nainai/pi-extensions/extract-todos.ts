/**
 * Extract TODOs Extension
 *
 * Provides a `/extract-todos` command that scans the current working
 * directory for TODO/FIXME/HACK/XXX markers in source files and prompts
 * the agent to create todo entries for them.
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import path from "node:path";
import { promises as fs } from "node:fs";

// TODO patterns to match (case-insensitive)
const TODO_PATTERNS = [
  /TODO(?:\([^)]*\))?:\s*(.+?)(?=\n|$)/gi,
  /FIXME:\s*(.+?)(?=\n|$)/gi,
  /HACK:\s*(.+?)(?=\n|$)/gi,
  /XXX:\s*(.+?)(?=\n|$)/gi,
] as const;

interface ExtractedTodo {
  file: string;
  line: number;
  text: string;
  tag: "TODO" | "FIXME" | "HACK" | "XXX";
}

/**
 * Common directories to skip during recursive scan.
 */
const SKIP_DIRS = new Set([
  "node_modules",
  ".git",
  "dist",
  "build",
  ".next",
  "__pycache__",
  ".pi",
  ".nix-darwin",
  ".venv",
  "venv",
  ".tox",
  ".mypy_cache",
  ".pytest_cache",
  ".eslintcache",
  ".DS_Store",
]);

/**
 * File extensions to scan for TODO markers.
 */
const SCAN_EXTS = new Set([
  ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs",
  ".py", ".pyi",
  ".rs", ".go", ".java", ".c", ".cpp", ".h", ".hpp", ".cc", ".hh",
  ".rb", ".lua", ".php", ".swift", ".kt", ".scala",
  ".sh", ".bash", ".zsh",
  ".md", ".txt", ".rst",
  ".yaml", ".yml", ".toml", ".json", ".xml",
  ".css", ".scss", ".sass", ".less",
  ".sql",
  ".vue", ".svelte", ".astro",
]);

/**
 * Recursively find all source files in a directory.
 */
async function findSourceFiles(dir: string): Promise<string[]> {
  const results: string[] = [];

  let entries: fs.Dirent[];
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch {
    return results; // Skip unreadable directories
  }

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      results.push(...(await findSourceFiles(fullPath)));
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name).toLowerCase();
      if (SCAN_EXTS.has(ext)) {
        results.push(fullPath);
      }
    }
  }

  return results;
}

/**
 * Extract TODOs from a single file.
 */
async function extractFromFilePath(filePath: string): Promise<ExtractedTodo[]> {
  const todos: ExtractedTodo[] = [];
  let content: string;

  try {
    content = await fs.readFile(filePath, "utf8");
  } catch {
    return todos; // Skip unreadable files
  }

  const lines = content.split("\n");

  for (let lineNum = 0; lineNum < lines.length; lineNum++) {
    const line = lines[lineNum];

    for (const pattern of TODO_PATTERNS) {
      pattern.lastIndex = 0; // Reset regex state
      const match = pattern.exec(line);
      if (match) {
        const tag = match[0].split(":")[0].toUpperCase() as ExtractedTodo["tag"];
        const text =
          match[1]?.trim() ||
          match[0].replace(/^(TODO|FIXME|HACK|XXX)(?:\([^)]*\))?:\s*/, "");

        if (text) {
          todos.push({
            file: filePath,
            line: lineNum + 1,
            text,
            tag,
          });
        }
      }
    }
  }

  return todos;
}

/**
 * Emoji mapping for TODO tags.
 */
const TAG_EMOJI: Record<ExtractedTodo["tag"], string> = {
  TODO: "📝",
  FIXME: "🐛",
  HACK: "⚠️",
  XXX: "❗",
};

/**
 * Build a natural-language prompt for the agent to create todos.
 */
function buildTodoPrompt(todos: ExtractedTodo[]): string {
  if (todos.length === 0) return "";

  // Group by file
  const byFile = new Map<string, ExtractedTodo[]>();
  for (const todo of todos) {
    const existing = byFile.get(todo.file) || [];
    existing.push(todo);
    byFile.set(todo.file, existing);
  }

  const lines: string[] = [];
  lines.push(
    `I found ${todos.length} TODO/FIXME/HACK/XXX marker(s) in ` +
    `${byFile.size} file(s) in the current project.`
  );

  for (const [file, fileTodos] of byFile) {
    const relPath = path.relative(process.cwd(), file);
    lines.push("");
    lines.push(`**${relPath}:**`);
    for (const todo of fileTodos) {
      const emoji = TAG_EMOJI[todo.tag] || "📝";
      lines.push(`  - Line ${todo.line}: ${emoji} ${todo.text}`);
    }
  }

  lines.push("");
  lines.push(
    "Please create individual todo entries for each of these items " +
    "using the `todo` tool. Group related items when appropriate."
  );

  return lines.join("\n");
}

/**
 * Perform the TODO extraction and send the prompt.
 */
async function extractAndNotify(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<void> {
  const cwd = ctx.cwd;

  // Find all scanable source files
  const files = await findSourceFiles(cwd);
  if (files.length === 0) {
    ctx.ui.notify("No scannable source files found in the current directory.", "info");
    return;
  }

  // Extract TODOs from all files
  const allTodos: ExtractedTodo[] = [];
  for (const file of files) {
    allTodos.push(...(await extractFromFilePath(file)));
  }

  // Remove duplicates (same file + line)
  const seen = new Set<string>();
  const uniqueTodos = allTodos.filter((t) => {
    const key = `${t.file}:${t.line}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  if (uniqueTodos.length === 0) {
    ctx.ui.notify("No TODO/FIXME/HACK/XXX markers found.", "info");
    return;
  }

  // Notify the user about what was found
  const uniqueFiles = new Set(uniqueTodos.map((t) => t.file)).size;
  ctx.ui.notify(
    `Found ${uniqueTodos.length} TODO/FIXME/HACK/XXX marker(s) in ${uniqueFiles} file(s)`,
    "info"
  );

  // Build and send the prompt — the agent will call the `todo` tool
  const prompt = buildTodoPrompt(uniqueTodos);
  if (prompt) {
    pi.sendUserMessage(prompt);
  }
}

/**
 * Extension factory.
 */
export default function extractTodosExtension(pi: ExtensionAPI) {
  pi.registerCommand("extract-todos", {
    description: "Scan the project for TODO/FIXME/HACK/XXX markers and suggest creating todo entries",
    handler: async (_args, ctx) => {
      await extractAndNotify(pi, ctx);
    },
  });
}
