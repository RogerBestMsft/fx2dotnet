# Planning Rules

Rules and policies governing how the fx2dotnet Planner synthesizes migration plans.

## Core Principles

1. **Assessment is the source of truth** — all classifications, dependency layers, and package data come from the assessment. The planner does not re-classify projects or re-analyze packages.
2. **Dependency-layer ordering** — SDK conversion and multitarget phases process projects in layer order: Layer 1 first, then Layer 2, etc. Projects within the same layer are ordered by `projectId` lexical ascending.
3. **Smallest safe changes** — package chunks are sized to minimize blast radius. Related packages are grouped; unrelated packages go in separate chunks.
4. **No silent surprises** — every blocking risk, uncertain classification, and missing resolution must appear in the Open Questions section. Migration does not proceed past these until the user responds.

## SDK Conversion Action Rules

| Classification | Action | Rationale |
|---|---|---|
| Already SDK-style | `skip-already-sdk` | No conversion needed |
| Legacy, not web-app-host | `needs-sdk-conversion` | Eligible for `convert_project_to_sdk_style` |
| Web application host | `web-app-host` | Handled in Phase 6; skip SDK conversion phase |
| Uncertain | `uncertain-web` | Requires user confirmation before action is assigned |
| Windows Service | `needs-sdk-conversion` + `windows-service` | Convert format; migrate service hosting in multitarget phase |

## Package Chunk Sizing Rules

1. Maximum packages per chunk: `config.planning.max_packages_per_chunk` (default: 5).
2. Group packages by logical area (EF, logging, DI, testing) into the same chunk when possible.
3. Never mix a `blocking` risk package with others in the same chunk.
4. Order chunks: low risk → medium risk → high risk → blocking.
5. If `stop_on_blocking_packages: true`: stop and ask for user approval before adding blocking chunks to the plan.

## EF6 Policy

See `docs/ef6-migration-policy.md`. Summary:
- EF6 packages are NEVER placed in the upgrade queue.
- EF6 is always marked `retain-as-is` in the plan.
- The plan notes that EF Core migration is a separate post-modernization activity.

## Windows Service Policy

See `docs/windows-service-migration.md`. Summary:
- Classify with both `needs-sdk-conversion` and `windows-service` action.
- Note in the plan that multitarget phase handles `ServiceBase` → `BackgroundService` migration.

## Web Migration Candidate Selection

- Exactly one web-app-host: auto-select as migration candidate.
- Multiple web-app-hosts: list all; require user to select one or confirm order.
- No web-app-hosts: mark Phase 6 as `skippable`.
