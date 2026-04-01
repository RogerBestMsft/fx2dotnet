# .NET Package Compatibility Migration

This extension wraps the package update execution phase of the migration workflow. It applies the plan produced earlier in the workflow rather than performing fresh assessment.

## Command

- Command: `speckit.fx-package-compat.migrate`
- Argument hint: provide a solution path, target framework, and the prepared package update plan.
- Backing file: `agents/package-compat-core.agent.md`

## Intended Usage

This extension is designed for orchestrator delegation, not direct manual use. It expects `.fx2dotnet/package-updates.md` to already contain a chunked package migration plan.

## State

Execution status is tracked in `.fx2dotnet/package-updates.md`, with the shared `alwaysContinue` preference stored in `.fx2dotnet/preferences.md`.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet