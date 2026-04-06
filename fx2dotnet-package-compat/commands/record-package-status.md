---
description: "Record the result of a completed package chunk in package-updates.md"
---

# Record Package Status

Update `.fx2dotnet/package-updates.md` after a chunk completes, is blocked, or is explicitly skipped with approval.

## User Input

$ARGUMENTS

Required:
- `chunkId`
- `status` (`completed`, `blocked`, or `skipped-approved`)
- `packagesUpdated`
- `buildFixOutcome`

## Steps

### Step 1: Read package-updates.md

Read `.fx2dotnet/package-updates.md` and locate the specified chunk.

### Step 2: Update Chunk Status

Update the chunk section:

```markdown
### Chunk 3: Logging package upgrades
- Status: completed
- Completed: 2026-04-03T12:45:00Z
- Packages Updated:
  - Serilog 2.10.0 -> 3.0.1
- Build Fix Outcome: build-success
```

### Step 3: Append Execution Log Entry

Append to `## Execution Log`:

```markdown
- 2026-04-03T12:45:00Z — Chunk 3 completed — Packages: Serilog 2.10.0 -> 3.0.1 — Outcome: build-success
```

### Step 4: Return

Return a brief summary of the recorded status.
