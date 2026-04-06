---
description: "Update a project from TargetFramework to TargetFrameworks and add requested modern TFMs"
---

# Add Target Frameworks

Add requested modern target frameworks to a project and convert `TargetFramework` to `TargetFrameworks` when needed. This command is the entry point for the multitarget phase.

## Constraints

- Make the smallest possible project-file change.
- Do not add new NuGet packages without user approval.
- When `System.Web` types are later encountered, apply System.Web Adapters policy rather than rewriting to native ASP.NET Core types.
- When Windows Service types are later encountered, apply Windows Service migration policy.

## User Input

$ARGUMENTS

Required: project or solution path.  
Optional: requested target frameworks (default: `net10.0`).

## Steps

### Step 1: Planning Gate

Invoke the planning subagent before making any changes. Persist its accepted output to `## Multitarget` as `refinedPlan`.

### Step 2: Read Project File

Read the target project file and inspect the current `TargetFramework` or `TargetFrameworks` property.

### Step 3: Apply Target Framework Change

- If the project has `TargetFramework`, replace it with `TargetFrameworks` containing the existing framework plus the requested framework(s).
- If the project already has `TargetFrameworks`, append the requested framework(s) if missing.
- Preserve the existing framework identifier exactly (e.g., `net48`, `net472`).

### Step 4: Record State

Write or update `## Multitarget` in `{solutionDir}/.fx2dotnet/{ProjectStateFile}.md`:

```markdown
## Multitarget
- refinedPlan: {summary}
- currentFrameworks: {existing}
- requestedFrameworks: {requested}
- status: target-frameworks-added
```

### Step 5: Hand Off to API Validation

Run `speckit.fx2dotnet-multitarget.validate-api-gaps`.
