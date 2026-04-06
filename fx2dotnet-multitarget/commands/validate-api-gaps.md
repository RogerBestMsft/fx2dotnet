---
description: "Identify and remediate API gaps introduced by added target frameworks"
---

# Validate API Gaps

After adding new target frameworks, build the project and identify API gaps introduced by the new TFMs. Use Build Fix to resolve issues one group at a time.

## User Input

$ARGUMENTS

Required: project path.

## Steps

### Step 1: Run Build Fix

Invoke `speckit.fx2dotnet-build-fix.diagnose-build`.

### Step 2: Apply Domain Policies

For errors involving:
- `System.Web` types → use System.Web Adapters policy
- EF6 types → use EF6 retention policy
- Windows Service types → use Windows Service migration policy

### Step 3: Iterate

Apply `apply-fix-pattern` → `retry-build` until:
- Build succeeds, or
- A blocker is reached, or
- The user stops.

### Step 4: Record Result

Update `## Multitarget` with:

```markdown
- apiGapStatus: resolved | blocked
- lastValidated: {ISO-8601}
```
