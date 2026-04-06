---
description: "Run dotnet build via subagent and classify all errors into categorized error groups for targeted remediation"
---

# Diagnose Build

Run `dotnet build` on the target project or solution and classify the resulting errors into named error groups. This is the entry point for a build-fix cycle.

## Constraints

- ALWAYS run `dotnet build`, `dotnet restore`, and other dotnet CLI commands via a **subagent** — never directly in the terminal.
- Delegate the command to a subagent and instruct it to return the full error list: error codes, messages, file paths, and line numbers.
- Filter out verbose/informational lines; return only diagnostics.

## User Input

$ARGUMENTS

Required: path to `.sln`, `.csproj`, `.vbproj`, or `.fsproj` file.  
Optional: callerPhase (e.g., `sdk-conversion`, `multitarget`) for state tagging.

## Steps

### Step 1: Resolve Target

Use the caller-provided target path. If not provided, search for project/solution files and ask the user to choose using `vscode/askQuestions`.

Derive:
- `{ProjectName}` = target file name without extension
- `{solutionDir}` = parent directory of the solution file
- `stateFile` = `{solutionDir}/.fx2dotnet/{ProjectName}.md`

### Step 2: Resume Check

Read `stateFile` and look for a `## Build Fix` section.

If found and contains unresolved error groups:
- Report how many groups remain and what was attempted.
- Ask whether to **resume** or **start fresh**.
- If resuming, load existing groups and return them.

### Step 3: Run Build via Subagent

Delegate to a subagent with instruction:

> Run `dotnet build {target}` and return: exit code, total error count, total warning count, and the complete list of compiler diagnostics (error code, message, file path, line number). Filter out informational and verbose output.

If the build succeeds (0 errors), report success, clear the `## Build Fix` section, and stop.

### Step 4: Parse and Group Errors

Extract all errors from the subagent output. Group them by error pattern:

| Group Type | Pattern |
|---|---|
| `missing-using` | CS0246 — type or namespace not found; infer missing `using` |
| `ambiguous-reference` | CS0104 — ambiguous between two namespaces |
| `missing-package` | CS0246 with package name in error message |
| `api-not-found` | CS1061, CS0103 — member/method not found (API removed or renamed) |
| `type-mismatch` | CS0029, CS0266 — incompatible types |
| `nullable-warning` | CS8600, CS8601, CS8602, CS8603, CS8618 — nullable reference warnings promoted to errors |
| `ef6-related` | Any error involving `System.Data.Entity` namespace |
| `systemweb-related` | Any error involving `System.Web` namespace |
| `service-related` | Any error involving `System.ServiceProcess` namespace |
| `other` | All remaining errors |

### Step 5: Write State

Create or update the `## Build Fix` section in `stateFile` using the `edit` tool:

```markdown
## Build Fix

- target: {path}
- callerPhase: {phase}
- buildAttempt: 1
- totalErrors: {count}

### Error Groups

#### Group 1: missing-using
- files: [...]
- errorCode: CS0246
- count: {n}
- status: pending
- retryCount: 0
```

### Step 6: Return Groups

Return the classified error groups for the next `apply-fix-pattern` invocation.
