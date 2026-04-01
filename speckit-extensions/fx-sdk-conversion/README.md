# .NET SDK-Style Project Conversion

This extension wraps the legacy project normalization phase of the migration workflow. It converts a project file to SDK-style format and then hands off build repair to the Build Fix phase.

## Command

- Command: `speckit.fx-sdk-conversion.convert`
- Argument hint: provide a `.sln`, `.csproj`, `.vbproj`, or `.fsproj` path.
- Backing file: `commands/convert.md`

## Tool Requirements

This extension requires both MCP servers declared in its manifest:

- `Microsoft.GitHubCopilot.AppModernization.Mcp`
- `Swick.Mcp.Fx2dotnet`

## State

Per-project conversion state belongs in the `## SDK Conversion` section of `.fx2dotnet/{ProjectName}.md`.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet