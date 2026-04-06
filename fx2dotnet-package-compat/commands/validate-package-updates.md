---
description: "Validate package-updates.md execution ledger for consistency, chunk ordering, and terminal statuses"
---

# Validate Package Updates

Validate `.fx2dotnet/package-updates.md` to ensure the chunk queue and execution ledger remain internally consistent.

## User Input

$ARGUMENTS

Required: solution path.

## Steps

### Step 1: Read package-updates.md

Read `.fx2dotnet/package-updates.md` using the `read` tool.

### Step 2: Validate Structure

Confirm the file contains:
- `## Compatibility Findings`
- `## Chunked Update Queue`
- `## Execution Log`

### Step 3: Validate Chunk Ordering

Check that chunk IDs are sequential and that each chunk has:
- Description
- Status
- Package list
- Risk level

### Step 4: Validate Execution Ledger

Ensure every chunk with `status: completed`, `blocked`, or `skipped-approved` has a matching execution-log entry recording:
- Completion timestamp
- Packages updated
- Build-fix outcome

### Step 5: Report

Return a pass/fail result with any structural violations or missing execution records.
