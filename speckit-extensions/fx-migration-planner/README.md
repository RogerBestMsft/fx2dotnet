# .NET Migration Planner

This extension wraps the planner phase that converts assessment findings into an execution sequence for the broader migration workflow.

## Command

- Command: `speckit.fx-migration-planner.plan`
- Argument hint: provide assessment content, ordered projects, dependency layers, solution path, and target framework.
- Backing file: `agents/migration-planner.agent.md`

## Intended Usage

This extension is designed for orchestrator delegation, not direct manual use. It depends on prior assessment output and does not perform code or project edits.

## Output

The planner produces a structured migration plan intended for `.fx2dotnet/plan.md` so the orchestrator can drive later phases from a stable plan.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet