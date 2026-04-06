---
description: "Apply the smallest possible fix to one classified error group, then record the attempt"
tools:
  - "read"
  - "edit"
  - "search"
---

# Apply Fix Pattern

Apply the minimal fix for one error group identified by `diagnose-build`. Make the smallest change that resolves the error group — no refactoring, no drive-by improvements.

## Constraints

- Make the SMALLEST possible change to fix each error — one logical fix at a time.
- ALWAYS read the file and surrounding context before editing.
- NEVER refactor, rename, or "improve" code beyond what is strictly needed to resolve the build error.
- NEVER add new NuGet package dependencies without asking the user first.
- Group identical fixes (e.g., adding the same `using` directive to multiple files) into a single batch — these count as one logical fix.

## When to Apply Domain Policies

Before applying fixes, check for domain-specific error types and load the relevant policy:

| Error Type | Policy |
|---|---|
| `System.Web` types (HttpContext, HttpRequest, HttpResponse, IHttpModule, IHttpHandler, HttpApplication) | Load and follow `systemweb-adapters` policy: use `Microsoft.AspNetCore.SystemWebAdapters` — do NOT rewrite to native ASP.NET Core types |
| Entity Framework 6 types (`System.Data.Entity`) | Load and follow `ef6-migration-policy`: retain EF6 packages — do NOT replace with EF Core |
| `System.ServiceProcess` types (ServiceBase, ServiceController, ServiceInstaller) | Load and follow `windows-service-migration` policy: replace with `BackgroundService` + `Microsoft.Extensions.Hosting.WindowsServices` |

## User Input

$ARGUMENTS

Required: error group to fix (from `diagnose-build` output), project state file path.

## Steps

### Step 1: Load Context

Read the state file `## Build Fix` section to find the target error group and its status.

Read the source files referenced by the errors using the `read` tool.

### Step 2: Select Fix Strategy

Based on error group type:

| Group Type | Fix Strategy |
|---|---|
| `missing-using` | Add the correct `using` directive to each affected file |
| `ambiguous-reference` | Add a fully-qualified type reference or explicit alias |
| `missing-package` | Ask user before adding any NuGet reference |
| `api-not-found` | Find the replacement API or use conditional compilation (`#if`) |
| `type-mismatch` | Add an explicit cast or use the correct type |
| `nullable-warning` | Add null check or null-forgiving operator at the specific site |
| `ef6-related` | Apply EF6 policy — do not touch EF6 code unless it causes a compile error from another source |
| `systemweb-related` | Apply System.Web Adapters policy — add package, do not rewrite |
| `service-related` | Apply Windows Service policy — migrate to BackgroundService |

### Step 3: Apply Fix

Use the `edit` tool to apply the fix. Make the smallest edit that resolves the error.

### Step 4: Update State

Increment `retryCount` for the error group and set `status: fix-applied` in the `## Build Fix` section:

```markdown
#### Group 1: missing-using
- status: fix-applied
- retryCount: 1
- lastFix: Added `using System.Linq` to 3 files
```

### Step 5: Report

Report what was changed and how many files were affected.
