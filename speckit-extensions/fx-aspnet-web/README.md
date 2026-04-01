# ASP.NET Framework to ASP.NET Core Web Migration

This extension wraps the web-host migration phase for classic ASP.NET applications.

## Command

- Command: `speckit.fx-aspnet-web.migrate`
- Argument hint: provide the legacy web project path and optionally the solution path and target framework.
- Backing file: `agents/aspnet-framework-to-aspnetcore-web-migration.agent.md`

## Intended Usage

This extension is designed for orchestrator delegation, not direct manual use. It assumes non-host libraries have already been assessed and migrated enough to support host migration.

## State

Progress belongs in the `## Web Migration` section of `.fx2dotnet/{ProjectName}.md`.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet