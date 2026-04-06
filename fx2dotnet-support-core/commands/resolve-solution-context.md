---
description: "Normalize solution path, derive solutionDir and stateRoot, and validate inputs before any migration command runs"
---

# Resolve Solution Context

Normalize the provided solution path into canonical `solutionDir` and `stateRoot` values that all other fx2dotnet commands use. This command is the standard preamble for any command that needs to locate `.fx2dotnet/` state.

## User Input

$ARGUMENTS

Accepts a `.sln` or `.slnx` file path, or a directory path. If omitted, searches the workspace.

## Steps

### Step 1: Locate Solution File

If the caller provides a path:
1. If it ends in `.sln` or `.slnx` — use it directly.
2. If it is a directory — search it for `.sln` and `.slnx` files.
3. If it is any other file extension — report an error: only `.sln` and `.slnx` are supported.

If no path is provided:
1. Search the workspace for `.sln` and `.slnx` files using the `search` tool.
2. If exactly one is found, use it automatically.
3. If multiple are found, present them and ask the user which one to use with `vscode/askQuestions`.
4. If none are found, stop and report that no solution file was detected.

### Step 2: Derive Context Paths

From the resolved solution file path produce:

```
solutionPath  = absolute path of the .sln or .slnx file
solutionDir   = parent directory of solutionPath
stateRoot     = {solutionDir}/.fx2dotnet/
```

Normalize all path separators to forward slashes for cross-platform consistency.

### Step 3: Validate Solution File is Readable

Use the `read` tool to confirm the solution file is readable. If the read fails, stop and report the error.

### Step 4: Return Context

Return the resolved context for use by the calling command:

```
solutionPath: {absolute path}
solutionDir:  {parent directory}
stateRoot:    {solutionDir}/.fx2dotnet/
```

If the stateRoot directory does not yet exist (first run), report that `.fx2dotnet/` has not been initialized and note that the first phase command will create it.
