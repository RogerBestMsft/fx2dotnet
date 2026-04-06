---
description: "Resume a workflow from the last project-and-phase checkpoint"
---

# Resume

Resume a previously started modernization workflow from the exact project-and-phase checkpoint recorded in `.fx2dotnet/plan.md`.

## User Input

$ARGUMENTS

Optional: solution path. Uses current solution context if omitted.

## Steps

### Step 1: Read plan.md

Read `.fx2dotnet/plan.md` and inspect:
- `lastCompletedPhase`
- `## Per-Project Phase Matrix`
- Any blocked rows or uncertainty markers

### Step 2: Determine Checkpoint

Identify the next unit of work using the matrix:
- First incomplete or blocked project in the current phase, ordered by layer and `projectId`
- If current phase is fully complete, advance to the next phase

### Step 3: Validate Gate

Run `speckit.fx2dotnet-orchestrator.validate-phase-gates` before entering the next phase.

### Step 4: Dispatch

Invoke the appropriate phase command for the selected project or chunk.

### Step 5: Update plan.md

Record the resumed checkpoint and current status.
