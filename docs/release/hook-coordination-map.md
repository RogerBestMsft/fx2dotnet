# Hook Coordination Map

Generated: 2026-04-03T22:58:53.6646384Z

| Extension | Hook | Command | Optional | Prompt |
|---|---|---|---|---|
| fx2dotnet-assessment | after_tasks | speckit.fx2dotnet-assessment.run | True | Would you like to run the .NET migration assessment on this solution? |

Only bootstrap assessment uses a hook. Phase-to-phase execution remains orchestrator-driven to preserve deterministic sequencing.
