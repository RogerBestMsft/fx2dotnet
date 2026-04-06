---
description: "Produce a risk summary from assessment data, highlighting blocking packages, uncertain classifications, and high-risk migration decisions"
---

# Summarize Risks

Read the assessment data and produce a concise risk summary identifying the most important decisions and potential migration blockers. This summary accompanies the migration plan and can be presented to stakeholders before execution begins.

## User Input

$ARGUMENTS

Optional: solution path (uses current solution context if omitted).

## Steps

### Step 1: Load Assessment Data

Read `.fx2dotnet/analysis.md` and `.fx2dotnet/package-updates.md` using the `read` tool.

### Step 2: Identify Risk Categories

Classify each risk item:

| Risk Category | Examples |
|---|---|
| **Blocking** | Package with no compatible version, unsupported library with no replacement |
| **High** | Package requiring breaking API changes, uncertain project classification |
| **Medium** | Package with major version upgrade, OWIN/identity dependencies |
| **Low** | Minor version upgrades, straightforward replacements |
| **Deferred** | Out-of-scope items requiring post-migration work |

### Step 3: Identify OWIN/Identity Risks

If any project references `Microsoft.Owin.*` or `Microsoft.AspNet.Identity.*`:
- Flag as a High risk item.
- Note: OWIN identity dependencies require an explicit user decision on replacement strategy during web migration planning. Do not auto-substitute ASP.NET Core Identity without approval.

### Step 4: Produce Risk Summary

Write the risk summary as a structured report:

```markdown
# Migration Risk Summary

**Solution**: {path}
**Assessment Date**: {date}

## Risk Overview

| Category | Count |
|----------|-------|
| Blocking | {count} |
| High | {count} |
| Medium | {count} |
| Low | {count} |
| Deferred | {count} |

## Blocking Risks

### {PackageId or classification}
- **Reason**: {explanation}
- **Required Action Before Migration**: {action}

## High Risks

### {item}
- **Reason**: {explanation}
- **Recommended Approach**: {approach}

## Open Decisions Required

{List of decisions that must be made before migration can proceed}

## Deferred Items

{List with post-migration action reminders}
```

### Step 5: Return Summary

Return the summary and flag whether any **Blocking** risks exist that would prevent immediate migration start.
