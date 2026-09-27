# check-review-comments

Judge existing PR review comments against the code. A comment is a claim, not a fact — the code decides.

You do NOT review the PR yourself. Do not add findings nobody commented on.

## Scope

Plain git for everything, GitHub REST API only where git cannot answer.

```bash
git rev-parse --git-dir                       # must be a repo
git status --porcelain                        # clean == empty output (ignore ?? lines); non-zero exit = abort and show the git error
REMOTE=$(git remote | grep -qx origin && echo origin || git remote | head -1)
git fetch "$REMOTE" "refs/pull/<iid>/head"
git checkout -B check-comments-pr-<iid> FETCH_HEAD
git fetch "$REMOTE" "<target-branch>"
```

- If the local HEAD already equals the PR head commit (you are on the source branch with a clean tree), skip fetch/checkout entirely and say so. Judging the same SHA is the point; creating a scratch branch is not.
- Never run this skill during an active `/review-mr` session: that extension owns `review-pr-<iid>`. This skill uses `check-comments-pr-<iid>` so the two never collide.
- Before `checkout -B`: if `refs/heads/check-comments-pr-<iid>` exists and differs from `FETCH_HEAD`, stop and tell the user to `git branch -D` it. Never silently reset it.
- Target branch: from the PR JSON (below) -> `base.ref`. If the API is unreachable, fall back to `git symbolic-ref refs/remotes/$REMOTE/HEAD --short`, then `main`/`master` — and say which fallback you used, because the diff may then include unrelated changes.
- Diff under judgement: `git merge-base HEAD "$REMOTE/<target-branch>"` then `git diff <sha> HEAD`. Never judge a comment against code outside that diff without saying so.
- Always confirm the PR's `head.sha` matches local HEAD. Different SHA = the comments target other code; say it before any verdict.

## Collect the comments

Get the GitHub token:

```bash
T=$(gh auth token)
OWNER_REPO=$(git remote -v | grep origin | head -1 | awk '{print $2}' | sed 's/\.git$//' | sed 's|git@github.com:||' | sed 's|https://github.com/||')
PR_IID=<number>
API="https://api.github.com/repos/$OWNER_REPO/pulls/$PR_IID"
curl -s -H "Authorization: Bearer $T" -H "Accept: application/vnd.github.v3+json" "$API"                       # title, state, head, base
curl -s -H "Authorization: Bearer $T" -H "Accept: application/vnd.github.v3+json" "$API/comments?per_page=100" > /tmp/pr<iid>.json
curl -s -H "Authorization: Bearer $T" -H "Accept: application/vnd.github.v3+json" "$API/comments/<comment-id>/reactions" > /tmp/reactions.json
```

If `gh` is not available or the token is empty, abort — do not proceed without authentication.

Parse with python, not by eye:

```bash
python3 - <<'EOF'
import json
for c in json.load(open('/tmp/pr<iid>.json')):
    p = c.get('path') or ''
    line = c.get('line') or c.get('original_line') or '(no position)'
    resolved = c.get('pull_request_review_id') is not None  # reviewed = resolved
    print('---', c['id'], c['user']['login'], p + ':' + str(line) if p else '(no location)', 'reviewed=', resolved)
    print(c['body'])
EOF
```

- Print bodies in full. Review-bot summaries carry "Findings" sections: those are real findings with no position; each one is its own numbered verdict. Truncating the body loses them.
- Attribute each comment to author + the `file:line` it quotes; if there is no position, mark it `(no location)` and resolve the file:line from the body, then verify by grep.
- Skip resolved comments (those attached to a `pull_request_review_id`) by default; include them only if the user asks.
- If the API call fails, the token is missing, or the comment list is empty while the PR clearly has discussion, stop and report. Never judge a partial comment list.

## Verdict per comment

Apply the `fact-check` skill's posture to each comment: prosecutor, not defense attorney — but here the *comment* is on trial, not the code.

For each comment emit exactly:

```
### <n>. @<author> — <file>:<line>
Claim: <one line, in your words>
Verdict: CONFIRMED | WRONG | UNCLEAR
Evidence: <cited code/diff lines that prove the verdict>
Fix: <smallest change that resolves it>   # CONFIRMED only
Reply: <what the author should answer in the PR>  # WRONG / UNCLEAR only
```

- CONFIRMED — the diff provably shows the problem. Quote the lines.
- WRONG — the code refutes the claim. Quote the lines that refute it.
- UNCLEAR — the diff neither proves nor refutes it. Name the exact missing information (file, config, runtime behavior); never guess a verdict.
- Answer in the language of the comment thread; keep paths, code, and the verdict keywords in English.

Use `fact-check`'s categories as priors when weighing a comment: silent error swallowing, unjustified fallbacks, unvalidated boundary input, always-true/false conditions, off-by-one.

## Offer the fix

After the verdict list, print a summary table (`n | verdict | file:line`) and ask the user which CONFIRMED comments to fix. Do not edit before that answer.

When fixing:

- Smallest change that resolves the comment. No refactoring, renaming, reformatting, or new abstractions.
- Touch no file that no CONFIRMED comment requires.
- No new `try/catch`, fallback, or default introduced to silence a comment — fail fast stays.
- One commit-sized change per comment; report changed files and one sentence per fix.
- Verify: build + the package tests that cover the touched code. Failures that also exist before your change (e.g. an unmigrated local test DB) are reported as pre-existing with the exact error — never silently absorbed, never "fixed" by weakening the test.
- Committing is a separate, explicitly requested step. If a pre-commit hook fails only on those pre-existing failures, say so and name the bypass instead of using it silently.

## Workflow

1. Parse the PR ref: a bare number, or `<iid>` from a `/<owner>/<repo>/pull/<iid>` URL.
2. Verify repo + clean tree, fetch `refs/pull/<iid>/head`, checkout `check-comments-pr-<iid>`, fetch and resolve the target branch.
3. Read the comments, drop resolved comments; stop if zero remain.
4. Compute the merge base and read the diff.
5. Emit one verdict block per comment, in PR order.
6. Print the summary table and ask which CONFIRMED items to fix.
7. Apply only the approved fixes, minimally; report changed files, skipped items and why.

## Principles

- The code is the evidence — a verdict without a quoted line is not a verdict.
- Never talk yourself out of a verdict — no "theoretically wrong but practically fine". Reviewers are wrong as often as authors.
- Partial data is a stop condition — a failed comment read aborts the run; it never degrades to a best-effort judgement. An unresolved target branch may proceed only with an explicit warning.
- Fixes are minimal and approved — no edit without an explicit user go-ahead on that comment.
- Never resolve or reply on GitHub — produce the text, the user posts it.
- Read-only against the remote — GET requests only. No comment creation, no resolve, no merge, no push.
