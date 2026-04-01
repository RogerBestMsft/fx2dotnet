# .NET Multitarget Migration

This extension wraps the phase that adds modern target frameworks to compatible projects and works through migration issues incrementally.

## Command

- Command: `speckit.fx-multitarget.migrate`
- Argument hint: provide a solution or project path and optionally the target frameworks to add.
- Backing file: `agents/multitarget.agent.md`

## State

Progress is stored in the `## Multitarget` section of `.fx2dotnet/{ProjectName}.md`, with shared continuation preferences in `.fx2dotnet/preferences.md`.

## Behavior

The command follows a planning-first workflow, uses minimal code changes, and delegates build verification to Build Fix after project file updates.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet