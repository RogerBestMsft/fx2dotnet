---
description: "Record multitarget phase status and API-gap resolution in per-project state"
---

# Record Multitarget State

Update the per-project `## Multitarget` section with the current status, requested frameworks, and API-gap resolution result.

## User Input

$ARGUMENTS

Required: project state file path, status values to record.

## Steps

### Step 1: Read Existing Multitarget Section

Read the current `## Multitarget` section from the project state file.

### Step 2: Update Status

Record fields such as:
- `currentFrameworks`
- `requestedFrameworks`
- `status`
- `apiGapStatus`
- `lastValidated`

### Step 3: Return Summary

Return the updated status summary.
