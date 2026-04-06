---
description: "Scaffold a new ASP.NET Core host project side-by-side with the legacy web project"
---

# Scaffold Core Host

Create a new ASP.NET Core web host project side-by-side with the legacy ASP.NET project. This command plans and scaffolds the replacement host without modifying the legacy host in place.

## Constraints

- Prefer a side-by-side replacement project over editing the legacy web project in place.
- Keep changes incremental and reversible.
- By default, stop after producing the migration plan and wait for user approval before major implementation.

## User Input

$ARGUMENTS

Required: legacy web project path.  
Optional: solution path, target framework (default: `net10.0`).

## Steps

### Step 1: Confirm Scope

Identify the legacy web project and confirm migration scope. If no project path is provided, ask the user for it.

### Step 2: Route Inventory

Invoke `speckit.fx2dotnet-web-route-inventory.inventory-routes`, `inventory-handlers`, and `inventory-modules` to build a complete endpoint inventory.

### Step 3: Build Migration Plan

From the inventory, define:
- New ASP.NET Core host project name and location
- Route and endpoint slices to port incrementally
- Hosting concerns (auth, modules, handlers)
- Open questions requiring user decision

Write or update `## Web Migration` in the legacy project's state file with the plan.

### Step 4: Scaffold New Host

Create the new ASP.NET Core project side-by-side with the legacy project using the chosen target framework.

### Step 5: Record State

Update `## Web Migration`:

```markdown
## Web Migration
- targetFramework: net10.0
- newHostProject: {path}
- status: core-host-scaffolded
```
