# .NET Build Fix

This extension wraps the iterative build-repair loop used throughout the migration workflow.

## Command

- Command: `speckit.fx-build-fix.fix`
- Argument hint: provide a `.sln`, `.csproj`, `.vbproj`, or `.fsproj` path.
- Backing file: `agents/build-fix.agent.md`

## Intended Usage

This extension is designed for orchestrator delegation, not direct manual use. Other migration phases call it after focused edits to validate and repair the current slice of work.

## State

Transient repair details belong in the `## Build Fix` section of `.fx2dotnet/{ProjectName}.md`.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet