# playwright

Node.js environment with Playwright and browsers pre-installed via Nix.

## Run

- File: `playwright-node /tmp/script.mjs`
- Inline: `playwright-node -e "import { chromium } from 'playwright'; const browser = await chromium.launch(); ..."`

ESM (`import`) and CommonJS (`require`) both resolve `playwright` out of the box.

## Principles

- Never set NODE_PATH or hunt for nix store paths — module resolution is handled by the `playwright-node` wrapper.
- Never call a system or global `playwright` install — only `playwright-node`.
- Write scripts to /tmp, not the skill directory (repo root if the user asks).
- Launch headless (the default); `headless: false` only when the user explicitly asks to watch.
- Give the bash tool 60s+ timeout — browser launch and page loads are slow.
