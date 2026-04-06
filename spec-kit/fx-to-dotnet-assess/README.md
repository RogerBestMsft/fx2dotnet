# fx-to-dotnet-assess — Assessment

Gather solution info, identify frameworks, dependencies, blockers; classify projects; audit package compatibility.

## Command

`speckit.fx-to-dotnet-assess.assess` — Pass the solution path to analyze.

## Prerequisites

- `fx-to-dotnet-detect-project` — for project classification
- `fx-to-dotnet-policies` — for migration policy references
- **MCP servers**: `Microsoft.GitHubCopilot.AppModernization.Mcp`, `Swick.Mcp.Fx2dotnet` (NuGet compat data)

## State Files

- Writes: `.fx-to-dotnet/analysis.md`, `.fx-to-dotnet/package-updates.md`
