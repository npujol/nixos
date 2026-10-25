import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

const VAULT_ROOT = path.join(os.homedir(), "Projects/personal/obsidian");
const MAX_RESULTS = 100;
const MAX_FILE_BYTES = 256 * 1024;

async function vaultPath(relativePath: string): Promise<string> {
  if (!relativePath || path.isAbsolute(relativePath)) {
    throw new Error("Path must be relative to the Obsidian vault.");
  }

  const root = await fs.realpath(VAULT_ROOT);
  const target = path.resolve(root, relativePath);
  if (target !== root && !target.startsWith(root + path.sep)) {
    throw new Error("Path must stay inside the Obsidian vault.");
  }
  return target;
}

function result(text: string, details?: unknown) {
  return { content: [{ type: "text" as const, text }], details };
}

const createNoteTool = defineTool({
  name: "foam_create_note",
  label: "Create Foam note",
  description:
    `Create a Markdown note in the Obsidian vault used by Foam (${VAULT_ROOT}). ` +
    "Always provide a vault-relative path, such as notes/topic.md. Creates parent folders. Refuses to overwrite existing notes.",
  parameters: Type.Object({
    path: Type.String({ description: "Vault-relative note path; .md is added if omitted" }),
    title: Type.String({ description: "Note title, used as a heading when content has no heading" }),
    content: Type.String({ description: "Markdown note body" }),
  }),
  async execute(_id, params) {
    const relative = params.path.endsWith(".md") ? params.path : `${params.path}.md`;
    const target = await vaultPath(relative);
    await fs.mkdir(path.dirname(target), { recursive: true });
    const parent = await fs.realpath(path.dirname(target));
    const root = await fs.realpath(VAULT_ROOT);
    if (parent !== root && !parent.startsWith(root + path.sep)) {
      throw new Error("Resolved note path escapes the Obsidian vault.");
    }
    const body = params.content.trimStart().startsWith("# ")
      ? params.content
      : `# ${params.title}\n\n${params.content}`;
    try {
      await fs.writeFile(target, body.endsWith("\n") ? body : `${body}\n`, { flag: "wx" });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "EEXIST") {
        throw new Error(`Note already exists: ${relative}`);
      }
      throw error;
    }
    return result(`Created note: ${relative}`, { path: relative, absolutePath: target });
  },
});

const readNoteTool = defineTool({
  name: "foam_read_note",
  label: "Read Foam note",
  description: `Read a Markdown note from the Obsidian vault used by Foam (${VAULT_ROOT}). Use a vault-relative path.`,
  parameters: Type.Object({
    path: Type.String({ description: "Vault-relative Markdown note path" }),
  }),
  async execute(_id, params) {
    const target = await vaultPath(params.path);
    const root = await fs.realpath(VAULT_ROOT);
    const parent = await fs.realpath(path.dirname(target));
    if (parent !== root && !parent.startsWith(root + path.sep)) {
      throw new Error("Resolved note path escapes the Obsidian vault.");
    }
    const stat = await fs.lstat(target);
    if (!stat.isFile() || stat.isSymbolicLink()) throw new Error("Note must be a regular file inside the vault.");
    if (stat.size > MAX_FILE_BYTES) throw new Error("Note exceeds the 256 KiB read limit.");
    return result(await fs.readFile(target, "utf8"), { path: params.path });
  },
});

const suggestTagsTool = defineTool({
  name: "foam_suggest_tags",
  label: "Suggest Foam tags",
  description:
    `Find notes with related content and suggest tags used in those notes. Searches only the Foam/Obsidian vault (${VAULT_ROOT}). ` +
    "Provide the draft note content and optionally its relative path to exclude it from related-note results.",
  parameters: Type.Object({
    content: Type.String({ description: "Draft note content to find related notes and tags for" }),
    path: Type.Optional(Type.String({ description: "Optional vault-relative path of the draft note" })),
  }),
  async execute(_id, params) {
    const root = await fs.realpath(VAULT_ROOT);
    const stopWords = new Set([
      "about", "after", "again", "also", "and", "are", "because", "been", "before", "being",
      "between", "but", "can", "could", "does", "each", "for", "from", "had", "has", "have",
      "into", "its", "just", "more", "most", "not", "only", "other", "our", "out", "over",
      "same", "some", "such", "than", "that", "the", "their", "them", "then", "there", "these",
      "they", "this", "those", "through", "under", "very", "was", "were", "what", "when", "where",
      "which", "while", "with", "would", "you", "your",
    ]);
    const words = (text: string) =>
      new Set((text.toLocaleLowerCase().match(/[a-z0-9][a-z0-9_-]{2,}/g) ?? []).filter((word) => !stopWords.has(word)));
    const draftWords = words(params.content);
    if (!draftWords.size) throw new Error("Draft content has no searchable terms.");

    const related: Array<{ path: string; score: number; tags: Set<string> }> = [];
    let visited = 0;
    async function visit(dir: string): Promise<void> {
      for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
        if (visited >= 1000) return;
        if (entry.isSymbolicLink() || entry.name === ".git" || entry.name === ".foam") continue;
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          await visit(fullPath);
        } else if (entry.isFile() && entry.name.endsWith(".md")) {
          visited++;
          const relative = path.relative(root, fullPath);
          if (params.path && relative === params.path) continue;
          const stat = await fs.stat(fullPath);
          if (stat.size > MAX_FILE_BYTES) continue;
          const text = await fs.readFile(fullPath, "utf8");
          const noteWords = words(text);
          let overlap = 0;
          for (const word of draftWords) if (noteWords.has(word)) overlap++;
          if (!overlap) continue;
          const noteTags = new Set<string>();
          for (const match of text.matchAll(/(?:^|\s)#([\p{L}\p{N}_/-]+)/gu)) noteTags.add(match[1].replace(/\/$/, ""));
          for (const match of text.matchAll(/^\s*tags\s*:\s*\[([^\]]*)\]/gim)) {
            for (const tag of match[1].split(",")) {
              const cleaned = tag.trim().replace(/^['\"]|['\"]$/g, "").replace(/^#/, "");
              if (cleaned) noteTags.add(cleaned);
            }
          }
          related.push({ path: relative, score: overlap / Math.sqrt(draftWords.size * Math.max(noteWords.size, 1)), tags: noteTags });
        }
      }
    }
    await visit(root);
    related.sort((a, b) => b.score - a.score);
    const topRelated = related.slice(0, 10);
    const tagScores = new Map<string, number>();
    for (const note of topRelated) {
      for (const tag of note.tags) tagScores.set(tag, (tagScores.get(tag) ?? 0) + note.score);
    }
    const suggestedTags = [...tagScores.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([tag]) => tag);
    const lines = [
      "Related notes:",
      ...(topRelated.length ? topRelated.map((note) => `- ${note.path} (similarity ${note.score.toFixed(2)})`) : ["- None found"]),
      "",
      `Suggested tags: ${suggestedTags.length ? suggestedTags.map((tag) => `#${tag}`).join(", ") : "No existing tags found in related notes"}`,
    ];
    return result(lines.join("\n"), { related: topRelated.map(({ path: notePath, score }) => ({ path: notePath, score })), suggestedTags, scannedNotes: visited });
  },
});

const searchNotesTool = defineTool({
  name: "foam_search_notes",
  label: "Search Foam notes",
  description: `Search note paths and Markdown content in the Obsidian vault used by Foam (${VAULT_ROOT}).`,
  parameters: Type.Object({
    query: Type.String({ description: "Case-insensitive text to search for" }),
  }),
  async execute(_id, params) {
    const root = await fs.realpath(VAULT_ROOT);
    const query = params.query.toLocaleLowerCase();
    const matches: string[] = [];
    async function visit(dir: string): Promise<void> {
      for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
        if (matches.length >= MAX_RESULTS) return;
        if (entry.isSymbolicLink() || entry.name === ".git" || entry.name === ".foam") continue;
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          await visit(fullPath);
        } else if (entry.isFile() && entry.name.endsWith(".md")) {
          const relative = path.relative(root, fullPath);
          if (relative.toLocaleLowerCase().includes(query)) {
            matches.push(relative);
            continue;
          }
          const stat = await fs.stat(fullPath);
          if (stat.size <= MAX_FILE_BYTES && (await fs.readFile(fullPath, "utf8")).toLocaleLowerCase().includes(query)) {
            matches.push(relative);
          }
        }
      }
    }
    await visit(root);
    return result(
      matches.length ? matches.join("\n") : "No matching notes found.",
      { matches, truncated: matches.length === MAX_RESULTS },
    );
  },
});

export default function (pi: ExtensionAPI) {
  pi.registerTool(createNoteTool);
  pi.registerTool(readNoteTool);
  pi.registerTool(searchNotesTool);
  pi.registerTool(suggestTagsTool);
}
