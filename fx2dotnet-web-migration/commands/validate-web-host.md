---
description: "Validate that the new ASP.NET Core host builds and preserves endpoint behavior"
---

# Validate Web Host

Validate the new ASP.NET Core host after each migration slice. Ensure it builds and preserve known endpoint behavior as closely as possible.

## User Input

$ARGUMENTS

Required: new host project path.

## Steps

### Step 1: Build Validation

Invoke the build-fix loop on the new host project.

### Step 2: Endpoint Validation

Compare the completed route slice against the inventory:
- Route template preserved
- HTTP verb preserved
- Auth requirement preserved
- Request/response contract preserved where obvious

### Step 3: Record Result

Update `## Web Migration` with validation status for the current slice.

### Step 4: Return

Return whether the host is ready for the next route slice or blocked.
