---
description: "Retry the build after a fix and evaluate whether the error group is resolved or needs further action"
---

# Retry Build

After a fix has been applied, run `dotnet build` again via subagent and evaluate the result. Update the error group status and determine whether to continue, escalate, or stop.

## Constraints

- ALWAYS run `dotnet build` via a **subagent** — never directly in the terminal.
- Check `max_retries_per_group` config before applying another fix. Stop if the limit is reached.

## User Input

$ARGUMENTS

Required: project/solution path, current error group being evaluated.

## Steps

### Step 1: Check Retry Limit

Read the `## Build Fix` section from the state file. Check `retryCount` for the current error group against `config.build_fix.max_retries_per_group` (default: 3).

If the limit is reached:
- Set group `status: blocked-max-retries`.
- Report the group as a blocker and ask how to proceed.
- Stop the fix loop for this group.

### Step 2: Run Build via Subagent

Delegate to a subagent:

> Run `dotnet build {target}` and return: exit code, total error count, and the complete diagnostic list (error code, message, file path, line number).

### Step 3: Evaluate Result

**If build succeeds (0 errors)**:
- Set group `status: resolved` in the state file.
- Report success.
- Check whether any other error groups remain pending.

**If errors remain but the previously fixed group is gone**:
- Set group `status: resolved`.
- Return remaining errors for the next `diagnose-build` → `apply-fix-pattern` cycle.

**If the same errors persist**:
- Increment `retryCount`.
- Set group `status: pending` (fix needs another attempt or a different strategy).
- Report that the fix did not resolve the issue and describe the remaining errors.

**If new errors appeared as a result of the fix**:
- Set the prior group `status: resolved` (original errors are gone).
- Classify and record the new errors as new groups.
- Return to the top of the build-fix loop.

### Step 4: Update State

Write the updated error group status and overall build attempt count back to the `## Build Fix` section.

```markdown
## Build Fix

- buildAttempt: 2
- totalErrors: 0

### Error Groups

#### Group 1: missing-using
- status: resolved
- retryCount: 1
- lastFix: Added `using System.Linq` to 3 files
```

### Step 5: Determine Next Action

| Outcome | Next Action |
|---|---|
| All groups resolved, build succeeds | Report success and stop |
| Some groups remain | Return remaining groups for next fix cycle |
| Group blocked (max retries) | Surface blocker summary and ask user for guidance |
| `throughput_mode: false` | Ask user whether to continue before starting next group |
