# .NET Solution Assessment

This extension wraps the assessment phase of the fx2dotnet migration workflow. It gathers a solution-wide modernization picture without making code changes.

## Command

- Command: `speckit.fx-assessment.run`
- Argument hint: provide the solution path to assess.
- Backing file: `commands/run.md`

## What It Produces

The command writes assessment outputs to `.fx2dotnet/analysis.md` and `.fx2dotnet/package-updates.md` under the target solution directory.

Those files include project ordering, dependency layers, project classifications, NuGet compatibility data, unsupported libraries, and out-of-scope findings for downstream planning.

## Tool Requirements

This extension requires both MCP servers declared in its manifest:

- `Microsoft.GitHubCopilot.AppModernization.Mcp`
- `Swick.Mcp.Fx2dotnet`

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet