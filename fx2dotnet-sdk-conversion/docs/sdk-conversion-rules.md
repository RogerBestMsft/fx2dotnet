# SDK Conversion Rules

Rules for the fx2dotnet SDK Conversion phase.

## Core Principles

1. The App Modernization MCP tool is the source of truth for project conversion.
2. The extension does not manually rewrite project files after MCP conversion.
3. Every converted project must pass through build validation before the phase is marked complete.
4. Stop per project on failure; do not continue to the next project automatically if `stop_on_per_project_failure: true`.

## Eligibility Rules

| Project Type | Conversion Action |
|---|---|
| Legacy class library | Convert |
| Legacy console app | Convert |
| Legacy web library | Convert |
| Legacy Windows Service | Convert |
| ASP.NET Framework web host | Skip — handled by web migration phase |
| Already SDK-style | Skip |

## State Section

Writes `## SDK Conversion` to `{solutionDir}/.fx2dotnet/{ProjectStateFile}.md`.

Required fields:
- `target`
- `conversionStatus`
- `buildStatus`
- `normalizationStatus`

## Failure Policy

If MCP conversion fails or output is unclear:
- Set `conversionStatus: failed`
- Record the MCP output summary
- Stop and ask the user how to proceed
