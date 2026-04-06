---
description: "Display current phase progress and per-project status matrix"
---

# Show Status

Read `.fx2dotnet/plan.md` and display the current workflow status in a concise format.

## User Input

$ARGUMENTS

Optional: solution path.

## Steps

### Step 1: Read plan.md

Read `.fx2dotnet/plan.md`.

### Step 2: Summarize Progress

Show:
- Current phase
- `lastCompletedPhase`
- Number of projects completed/blocked in the current phase
- Any open uncertainty markers

### Step 3: Show Matrix Snapshot

Display the per-project matrix rows with the most relevant columns for the current phase.
