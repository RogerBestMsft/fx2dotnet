---
description: "Validate phase-gate conditions before advancing the workflow"
---

# Validate Phase Gates

Validate that the current phase is complete and that all required state artifacts and statuses are present before advancing to the next phase.

## User Input

$ARGUMENTS

Required: `fromPhase`, `toPhase`.

## Steps

### Step 1: Run State Contract Validation

Invoke `speckit.fx2dotnet-support-core.validate-state-contract`.

### Step 2: Check Gate-Specific Conditions

| Gate | Condition |
|---|---|
| `assessment->planning` | `analysis.md` and `package-updates.md` exist and contain all projects |
| `planning->sdk-conversion` | `plan.md` exists with per-project matrix and no unresolved uncertainty markers |
| `sdk-conversion->package-compat` | All `needs-sdk-conversion` projects have `conversionStatus: completed` and `buildStatus: build-success` |
| `package-compat->multitarget` | All chunks in `package-updates.md` have terminal status |
| `multitarget->web-migration` | All non-web-host projects have `## Multitarget` terminal status |
| `web-migration->done` | All web-host projects have `## Web Migration` terminal status |

### Step 3: Report

Return pass/fail result with violations and warnings.
