---
description: "Apply one chunk of package version updates from package-updates.md, then invoke Build Fix"
---

# Apply Package Chunk

Apply one chunk of package version updates defined in `.fx2dotnet/package-updates.md`, then invoke Build Fix to validate the solution after the chunk. This command does not discover new updates — it only executes the plan.

## Constraints

- ONLY apply package updates defined in the provided plan — do not discover or re-evaluate packages.
- ALWAYS read project files and central package management files before editing.
- Prefer central package management updates (`Directory.Packages.props`) when present; otherwise update local project references.
- Apply updates in the chunk order provided by the plan.
- After each chunk, invoke Build Fix and evaluate the outcome before proceeding.
- If `always_continue` is false, ask the user whether to continue after each completed chunk.

## User Input

$ARGUMENTS

Required: solution path, `chunkId` from `package-updates.md`.

## Steps

### Step 1: Resolve State

Read `.fx2dotnet/package-updates.md` and locate the specified chunk.

If the chunk is already `completed`, report and stop.
If the chunk is `blocked` or `skipped-approved`, report its current status and stop.

### Step 2: Read Target Files

For each package update in the chunk:
- If a `Directory.Packages.props` file exists, read it first.
- Otherwise read the project file(s) containing the `PackageReference` to be updated.

### Step 3: Apply Only Planned Updates

Apply the package version changes listed in the chunk — nothing else.

If the chunk includes a **risky substitution** (`replace-with:` alternative package) and `config.package_compat.stop_on_risky_substitution: true`:
- Ask the user for approval before applying that substitution.

### Step 4: Invoke Build Fix

Run `speckit.fx2dotnet-build-fix.diagnose-build` on the solution. If errors are found, continue with `apply-fix-pattern` → `retry-build` until either:
- The build succeeds, OR
- An error group is blocked, OR
- User stops the fix loop.

### Step 5: Record Chunk Result

Call `speckit.fx2dotnet-package-compat.record-package-status` with:
- `chunkId`
- `status`: `completed`, `blocked`, or `skipped-approved`
- `packagesUpdated`
- `buildFixOutcome`

### Step 6: Continue or Stop

If `config.package_compat.always_continue: false`, ask the user whether to continue to the next chunk.
Otherwise proceed automatically.
