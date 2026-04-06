---
description: "Apply post-conversion normalization checks to the converted project file without changing the MCP tool’s source-of-truth behavior"
---

# Normalize Project File

Perform light post-conversion normalization checks after the MCP conversion tool runs. This command does not replace the MCP output; it verifies that the converted project file is in an acceptable normalized state for the rest of the workflow.

## Constraints

- Do not modify the project file manually unless the MCP conversion explicitly requires a follow-up normalization step documented here.
- Do not inspect or rewrite NuGet references.
- Use the smallest possible check surface — only the root project element and top-level properties when needed.

## User Input

$ARGUMENTS

Required: path to converted project file.

## Steps

### Step 1: Read Minimal Project File Context

Read only the minimal leading section of the converted project file needed to inspect:
- Root `<Project>` element
- `Sdk` attribute
- `TargetFramework` or `TargetFrameworks`
- Obvious leftover legacy imports if visible in the opening section

### Step 2: Validate Normalization

Check:
- Root is `<Project Sdk="...">`
- `TargetFramework` or `TargetFrameworks` is present
- No obvious legacy web-host imports remain in a non-web project

### Step 3: Record Result

Append a short note to `## SDK Conversion`:

```markdown
- normalizationStatus: valid
- normalizationNotes: Root uses SDK attribute and target framework is present
```

If invalid, mark:

```markdown
- normalizationStatus: needs-review
- normalizationNotes: {issue}
```

### Step 4: Return

Return the normalization status for orchestrator phase-gate evaluation.
