# refactor-patterns

Rewrite a pattern/context file (`CLAUDE.md`, `AGENTS.md`, `PATTERN.md`, `README` sections) into a terse, module-scoped doc, then record pattern violations as TODOs for another session to fix.

## Target format

```markdown
# <path/to/module> — <one-line role>

## <Module> responsibilities
- <verb phrase>
- <verb phrase>

## Principles

- <Principle name> — <why / how it is enforced>
```

Rules for the output:

- Scope one file per module/package. No repo-wide dumping grounds.
- Responsibilities: bullet verb phrases, no prose, no more than ~6.
- Principles: `<name> — explanation`, each an actual invariant, verifiable in code.
- Sacrifice grammar for brevity. No preamble, no "this document describes".
- Delete anything that is generic advice, restates the language docs, or is not enforced.
- Keep concrete names (types, funcs, packages) so principles are checkable.

## Workflow

1. Read the existing pattern file and the module code it describes.
2. Derive responsibilities from what the module actually does, not what the doc claims.
3. Extract principles: only invariants the code holds (or should hold) today.
4. Write the refactored file in the target format, replacing the old content.
5. Diff intent: list every dropped statement and why (stale / generic / unenforced).
6. Scan the module for violations of the documented principles.
7. For each violation, create a todo (`todo` tool, `create`) so a separate session fixes it:
   - title: `fix(<module>): <violation summary>`
   - body: file + line, which principle is violated, and the concrete fix
   - tags: `["pattern-violation"]`
8. Never fix violations in this session — documenting and filing TODOs is the deliverable.

## Principles

- Docs describe reality — If code and doc disagree, the doc states the intended invariant and a TODO records the gap.
- Terse over complete — A principle nobody reads is worthless; cut it.
- Every principle is checkable — If you cannot point at code that would violate it, it is not a principle.
- Violations become TODOs, not edits — Keep refactor of docs separate from refactor of code.
