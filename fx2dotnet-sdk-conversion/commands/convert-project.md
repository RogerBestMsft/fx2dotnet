---
description: "Convert a legacy .NET project file to SDK-style format using the App Modernization MCP convert_project_to_sdk_style tool"
tools:
  - "microsoft.githubcopilot.appmodernization.mcp/convert_project_to_sdk_style"
  - "Swick.Mcp.Fx2dotnet/GetMinimalPackageSet"
---

# Convert Project

Convert a legacy project file to SDK-style format using the `convert_project_to_sdk_style` MCP tool. The tool is the source of truth for conversion behavior and results.

## Constraints

- Use `convert_project_to_sdk_style` to perform the actual conversion — do NOT manually edit project files.
- Treat `convert_project_to_sdk_style` output as authoritative.
- Do not manually inspect NuGet package references, `packages.config`, `project.assets.json`, or other NuGet-related artifacts.
- Do not read an entire project file into context; inspect only the minimal root element if needed before conversion.
- Do not modify project files manually after MCP tool execution.

## User Input

$ARGUMENTS

Required: project file path (`.csproj`, `.vbproj`, or `.fsproj`).  
Optional: solution path for context.

## Steps

### Step 1: Resolve Target

Validate the provided project file exists and is a supported type. If not provided, search for project files and ask using `vscode/askQuestions`.

Derive:
- `{ProjectName}` = project file name without extension
- `{solutionDir}` = parent directory of the solution file
- `stateFile` = `{solutionDir}/.fx2dotnet/{ProjectName}.md`

Apply collision-safe file naming if needed (see WI-02 decision).

### Step 2: Resume Check

Read `stateFile` and look for a `## SDK Conversion` section.
- If `conversionStatus: completed` and `buildStatus: build-success` → report already done, stop.
- If `conversionStatus: completed` and build not successful → ask user whether to **resume Build Fix** or **start fresh**.
- If `conversionStatus: in-progress` or `failed` → ask whether to **retry** or **start fresh**.
- If section absent → proceed with fresh initialization.

### Step 3: Write Initial State

Create or update the `## SDK Conversion` section in `stateFile`:

```markdown
## SDK Conversion

- projectId: {projectId}
- displayName: {ProjectName}
- target: {absolute project path}
- conversionStatus: pending
- buildStatus: not-started
```

### Step 4: Invoke Conversion Tool

Call `convert_project_to_sdk_style` with the project file path. Do not pre-inspect the file.

If the tool call fails or the output indicates the project is already SDK-style:
- Record `conversionStatus: already-sdk-style` and stop.
- Report to the caller that this project does not need conversion.

### Step 5: Record Conversion Result

Update the `## SDK Conversion` section:

```markdown
- conversionStatus: completed
- conversionTimestamp: {ISO-8601}
- toolOutput: {summary of tool response}
```

If conversion fails:
- Set `conversionStatus: failed` with the error summary.
- Stop and report to the caller — do NOT proceed to Build Fix.

### Step 6: Run Build Validation

Invoke `speckit.fx2dotnet-sdk-conversion.validate-conversion` to trigger a build-fix pass.
