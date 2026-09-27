# update-changelog

Add to `CHANGELOG.md` the changes between the last release and `main` not yet incorporated.

Baseline version: "$ARGUMENTS"

## Workflow

1. Baseline: the provided version, else the latest tag — `git describe --tags --abbrev=0`.
2. Gather commits: `git log <baseline>..HEAD`.
3. Read the existing `CHANGELOG.md`; add missing changes to the "Unreleased" section (create it at the top if absent). Append to existing Unreleased content, never replace.

## Principles

- Only user-facing changes: features, fixes, breaking changes. Skip typo fixes, internal refactors, minor docs.
- Order: breaking changes first, then features, then fixes. Group related changes.
- Reference PRs (`#NUMBER`) when available; never raw commit hashes.
- Never delete or rewrite existing entries.
- Entries: bullet points starting with a past-tense verb; say what was fixed/added and why it matters, not just that it changed.
- Code references in backticks (`` `foo.cleanup` ``); match the file's existing style and formatting.
- When unsure whether a change is significant, include it.
