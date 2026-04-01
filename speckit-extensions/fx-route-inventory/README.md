# Legacy ASP.NET Route Inventory

This extension wraps the read-only endpoint inventory step used by the web migration workflow.

## Command

- Command: `speckit.fx-route-inventory.scan`
- Argument hint: provide the legacy web project path or containing folder.
- Backing file: `agents/legacy-web-route-inventory.agent.md`

## Intended Usage

This extension is designed for orchestrator delegation, not direct manual use. Its output feeds the ASP.NET Framework to ASP.NET Core migration phase.

## Behavior

The command scans route definitions and controller surfaces without editing code or project files.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet