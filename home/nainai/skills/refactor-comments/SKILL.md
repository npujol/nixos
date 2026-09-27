# refactor-comments

Refactor comments so that only WHY survives. Names and types explain WHAT; structure explains HOW. Comments that narrate code are noise and rot.

## Principles

> A comment must answer "why does this exist?" or "why is it done this way and not the obvious way?" — nothing else.

## Scope

- Before starting, ask whether this operates on the whole codebase or only on changes in the current branch/PR (`git diff main...HEAD`). Limit all subsequent steps to that scope.

## Delete on sight

1. Narration — restates the code:
   ```python
   # increment counter        ← delete
   counter += 1
   # loop over users          ← delete
   for user in users:
   ```
2. Section banners — `# ---- helpers ----`, `# // TODO section` separators. If a file needs banners, it needs splitting.
3. Docstring paraphrase — docstring repeats what the signature already says:
   ```python
   def send_email(to: str, subject: str) -> None:
       """Sends an email to the recipient with the given subject."""  ← delete
   ```
4. Redundant inline labels — `# returns true if valid` on a function named `is_valid() -> bool`.
5. Change log / attribution — `# added by X, 2023-04-01`, `# fix for ticket`. That's what git blame is for.
6. Dead code justification — commented-out code with a comment explaining it. Delete both.
7. Obvious param docs — `:param user: the user object`. Unless the param has a non-obvious constraint, delete.

## Keep only WHY

- Constraint — why this value/approach, not another: `PgBouncer requires per-request connections; do not raise CONN_MAX_AGE`.
- External quirk — workaround for a bug/API/behavior outside the codebase: `vendor API returns 200 on error; check payload`.
- Non-obvious tradeoff — why the slower/weirder path was chosen.
- Warning — landmines: `order matters: X must run before Y because …`.
- TODO/FIXME — keep, but only with a concrete trigger or owner; vague ones (`# TODO: improve`) get deleted.

## Be skeptical

Before deleting, ask:

1. Is this actually obvious? A comment that looks redundant to you may encode domain knowledge. `timeout=30` needs no comment; `timeout=30  # payment gateway hangs at 35s` is a WHY — keep the why, trim the rest.
2. Is the code lying? If a comment is needed because the code is unclear, the fix is usually renaming/extracting — not keeping the comment. Prefer: rename the variable/function so the comment becomes unnecessary, then delete it. Only do this when the rename is safe and local.
3. Does it drift? Comments that describe behavior (not intent) rot as code changes. Even a currently-correct WHAT comment is a future lie. Delete.
4. Is it load-bearing? Linter directives (`# noqa`, `# type: ignore`, `// eslint-disable`), shebangs, license headers, encoding pragmas are not comments — never touch them.

## Workflow

1. For each file, read the code — not just the comments. Judging "obvious" requires understanding.
2. Apply: delete narration, keep/trim WHY, rename only when it makes a comment deletable and the rename is trivially safe.
3. Report: per file, list deletions and keeps (with reason for keeps). If >50% of comments survived, you weren't critical enough — re-review.
4. Run the project's lint/tests after.
