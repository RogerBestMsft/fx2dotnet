---
description: "Validate that SDK-style conversion succeeded by running a full build-fix pass and recording the outcome"
---

# Validate Conversion

After `convert-project` completes, validate the converted project by running a build-fix loop. This ensures the converted project compiles successfully before the orchestrator moves to the next project in the layer.

## Constraints

- Stop on per-project failure — do NOT continue to the next project automatically if this project fails to build.

## User Input

$ARGUMENTS

Required: project file path, solution path.

## Steps

### Step 1: Run diagnose-build

Invoke `speckit.fx2dotnet-build-fix.diagnose-build` for the converted project. Pass `callerPhase: sdk-conversion`.

If the build succeeds immediately (0 errors):
- Update `buildStatus: build-success` in the `## SDK Conversion` section.
- Report success and stop.

### Step 2: Build-Fix Loop

While errors remain and retry limits have not been reached:
1. Invoke `speckit.fx2dotnet-build-fix.apply-fix-pattern` for the next unresolved error group.
2. Invoke `speckit.fx2dotnet-build-fix.retry-build`.
3. Evaluate result.

### Step 3: Record Final Build Status

Update the `## SDK Conversion` section with the final build outcome:

```markdown
- buildStatus: build-success
- buildFixAttempts: {count}
- validationTimestamp: {ISO-8601}
```

Or on failure:

```markdown
- buildStatus: build-failed
- blockers: [{error group descriptions}]
```

### Step 4: Report to Caller

If `buildStatus: build-success` → report project as successfully converted and validated.

If `buildStatus: build-failed`:
- Per `config.conversion.stop_on_per_project_failure: true` — stop and report the project as blocked.
- Provide the blocker summary so the orchestrator can mark the project as `blocked` in the per-project matrix.
