---
description: "Validate that all required .fx2dotnet/ state files are present and structurally correct"
---

# Validate State Contract

Check that the `.fx2dotnet/` state directory for the current solution contains the expected files and that each file has the required structural sections. Emit phase-gate violations for missing or malformed content.

## Prerequisites

- Solution path must be resolved. Run `speckit.fx2dotnet-support-core.resolve-solution-context` first if not already done.

## User Input

$ARGUMENTS

Accepts an optional `solutionDir` path. If omitted, derives it from the nearest `.sln` or `.slnx` file.

## Steps

### Step 1: Locate State Root

Derive `stateRoot` from the provided or discovered solution path:

```
solutionDir  = parent directory of the .sln or .slnx file
stateRoot    = {solutionDir}/.fx2dotnet/
```

Use the `read` tool to check whether `stateRoot` exists by attempting to read `{stateRoot}/plan.md`. If the read fails (file not found), report that `.fx2dotnet/` has not been initialized and stop.

### Step 2: Check Required File Presence

Attempt to read each of the following files with the `read` tool:

| File | Required When |
|---|---|
| `.fx2dotnet/plan.md` | Always (after planning phase) |
| `.fx2dotnet/analysis.md` | After assessment phase |
| `.fx2dotnet/package-updates.md` | After assessment phase |

For each missing file, record a violation:

```
VIOLATION: Missing required state file: .fx2dotnet/{file}
```

### Step 3: Check plan.md Structure

If `plan.md` is present, verify it contains all required sections:

- `## Progress` table with Phase, Status, Completed, Notes columns
- `## Metadata` block with `lastCompletedPhase` field
- `## Per-Project Phase Matrix` table with `projectId` column

For each missing section, record a violation:

```
VIOLATION: plan.md missing required section: {section-name}
```

### Step 4: Check analysis.md Structure

If `analysis.md` is present, verify it contains:

- `## Project Inventory` table with `projectId` column
- `## Dependency Layers` section
- `## Project Classifications` section

### Step 5: Check Cross-File projectId Consistency

Extract the `projectId` set from each file that is present and compare:

- All `projectId` values in `analysis.md` must appear in `plan.md`
- All `projectId` values in `plan.md` must appear in `analysis.md`
- Any `projectId` in `package-updates.md` must be a subset of `analysis.md`'s set

Record violations for any discrepancies.

### Step 6: Check for Uncertainty Markers

Scan all state files for `<!-- uncertainty:` markers. If any are found, list them as warnings requiring user confirmation before phase continuation.

### Step 7: Report

Summarize the validation result:

```
State Contract Validation — {solutionDir}

Files checked:   3
Violations:      0
Warnings:        0

✓ State contract is valid. All phase gates can proceed.
```

If violations exist:

```
State Contract Validation — {solutionDir}

Files checked:   3
Violations:      2
Warnings:        1

✗ VIOLATION: Missing required state file: .fx2dotnet/package-updates.md
✗ VIOLATION: plan.md missing required section: ## Per-Project Phase Matrix
⚠ WARNING:  Uncertainty marker found in analysis.md — needs-user-confirmation for project: src/Web/Web.csproj

Action required: Resolve violations before proceeding to next phase.
```
