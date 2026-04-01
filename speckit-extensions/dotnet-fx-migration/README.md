# .NET Framework to Modern .NET Migration

This Spec-Kit extension wraps the repository's top-level migration orchestrator. It coordinates assessment, planning, SDK conversion, package compatibility work, multitargeting, and legacy ASP.NET web migration for a solution.

## Command

- Command: `speckit.dotnet-fx-migration.run`
- Argument hint: specify a `.sln` or `.slnx` path and optionally a target framework. The default target framework is `net10.0`.
- Backing file: `agents/dotnet-fx-to-modern-dotnet.md`

## Phase Overview

The command enforces the repository's migration order:

1. Assessment
2. Planning
3. SDK Conversion
4. Package Compatibility
5. Multitarget
6. ASP.NET Core Web Migration

Build Fix runs throughout those phases when build validation is required.

## State Files

The orchestrator stores and reuses migration state under the solution-local `.fx2dotnet/` folder:

- `plan.md`
- `analysis.md`
- `package-updates.md`
- `preferences.md`
- `{ProjectName}.md`

This layout allows interrupted migrations to resume safely.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet