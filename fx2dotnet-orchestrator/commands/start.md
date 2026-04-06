---
description: "Start a new end-to-end modernization workflow"
---

# Start

Start a new end-to-end .NET Framework → modern .NET migration workflow. This command initializes state, runs assessment and planning, then coordinates each phase in order.

## Constraints

- Enforce phase order strictly; do not skip or reorder phases.
- Run assessment and planning before any migration work.
- Process projects by dependency layer and stable `projectId` order.
- No silent continuation on phase failures — always surface blocked state and next action choices.

## User Input

$ARGUMENTS

Required: solution path.  
Optional: target framework (default: `net10.0`).

## Steps

### Step 1: Resolve Context

Run `speckit.fx2dotnet-support-core.resolve-solution-context`.

### Step 2: Resume Check

Read `.fx2dotnet/plan.md`.

If it exists and `lastCompletedPhase` is not `none`:
- Summarize current state.
- Ask whether to **resume** or **start fresh**.
- If resuming, hand off to `speckit.fx2dotnet-orchestrator.resume`.

### Step 3: Fresh Initialization

Create `.fx2dotnet/plan.md` with:
- Solution path
- Target framework
- `lastCompletedPhase: "none"`
- Empty per-project matrix (to be filled by planning)

### Step 4: Run Assessment

Invoke `speckit.fx2dotnet-assessment.run`.

### Step 5: Validate Assessment Gate

Invoke `speckit.fx2dotnet-orchestrator.validate-phase-gates` for `assessment->planning`.

### Step 6: Run Planner

Invoke `speckit.fx2dotnet-planner.generate-plan`.

### Step 7: Execute Migration Phases in Order

For each phase, validate gate then invoke phase commands in stable layer order:
1. SDK Conversion
2. Package Compatibility
3. Multitarget
4. Web Migration

Update `plan.md` after each phase and after each project checkpoint.

### Step 8: Return Summary

Report the workflow start result and current phase.
