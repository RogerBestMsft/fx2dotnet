---
description: "Port routes and endpoints incrementally from the legacy web host to the new ASP.NET Core host"
---

# Port Routes

Port routes and endpoints incrementally from the legacy ASP.NET host to the new ASP.NET Core host in small, validated slices.

## Constraints

- Keep changes incremental and reversible.
- Do not silently change public route shapes, auth behavior, or response contracts.
- Prefer adapter-based compatibility (`Microsoft.AspNetCore.SystemWebAdapters`) over wholesale rewrites when preserving behavior.

## User Input

$ARGUMENTS

Required: legacy web project path, new host project path.

## Steps

### Step 1: Read Web Migration Plan

Read `## Web Migration` from the legacy project state file and load the route inventory.

### Step 2: Select Slice

Port the next uncompleted route slice from the plan:
- One controller or one route group at a time
- Preserve route templates and auth requirements

### Step 3: Implement Slice

Port the selected slice into the new Core host. If a `System.Web` type is required, use `Microsoft.AspNetCore.SystemWebAdapters`.

### Step 4: Validate

Run `speckit.fx2dotnet-web-migration.validate-web-host` after each slice.

### Step 5: Record Progress

Update `## Web Migration` with completed slices and remaining work.
