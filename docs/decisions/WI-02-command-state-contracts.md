# WI-02: Command and State Contract Decision Record

**Status**: Done  
**Date**: April 3, 2026  
**Depends On**: WI-01  

---

## Command Naming Convention

All fx2dotnet extension commands follow this pattern exactly:

```
speckit.fx2dotnet-{extension-id}.{command-name}
```

### Locked Command Surface

| Extension | Command | Description |
|---|---|---|
| `fx2dotnet-support-core` | `speckit.fx2dotnet-support-core.validate-state-contract` | Validate `.fx2dotnet/` state file contracts |
| `fx2dotnet-support-core` | `speckit.fx2dotnet-support-core.resolve-solution-context` | Normalize solution path and derive state root |
| `fx2dotnet-support-core` | `speckit.fx2dotnet-support-core.invoke-mcp-wrapper` | Invoke MCP tools with fallback and timeout handling |
| `fx2dotnet-project-classifier` | `speckit.fx2dotnet-project-classifier.classify-project` | Classify a project as web host, library, service, etc. |
| `fx2dotnet-project-classifier` | `speckit.fx2dotnet-project-classifier.detect-sdk-style-status` | Determine whether a project uses SDK-style format |
| `fx2dotnet-assessment` | `speckit.fx2dotnet-assessment.run` | Run full solution assessment |
| `fx2dotnet-assessment` | `speckit.fx2dotnet-assessment.compute-layers` | Compute dependency layers for a solution |
| `fx2dotnet-assessment` | `speckit.fx2dotnet-assessment.collect-package-baseline` | Collect NuGet package baseline for compatibility check |
| `fx2dotnet-planner` | `speckit.fx2dotnet-planner.generate-plan` | Synthesize assessment output into migration plan |
| `fx2dotnet-planner` | `speckit.fx2dotnet-planner.summarize-risks` | Produce risk summary from assessment data |
| `fx2dotnet-build-fix` | `speckit.fx2dotnet-build-fix.diagnose-build` | Run build and classify errors |
| `fx2dotnet-build-fix` | `speckit.fx2dotnet-build-fix.apply-fix-pattern` | Apply one logical fix to a categorized error group |
| `fx2dotnet-build-fix` | `speckit.fx2dotnet-build-fix.retry-build` | Retry build after fix and evaluate outcome |
| `fx2dotnet-sdk-conversion` | `speckit.fx2dotnet-sdk-conversion.convert-project` | Convert a project to SDK-style format via MCP |
| `fx2dotnet-sdk-conversion` | `speckit.fx2dotnet-sdk-conversion.validate-conversion` | Validate post-conversion build and state |
| `fx2dotnet-sdk-conversion` | `speckit.fx2dotnet-sdk-conversion.normalize-project-file` | Apply post-conversion normalization |
| `fx2dotnet-package-compat` | `speckit.fx2dotnet-package-compat.apply-package-chunk` | Apply one chunk of package updates |
| `fx2dotnet-package-compat` | `speckit.fx2dotnet-package-compat.validate-package-updates` | Validate package update ledger for consistency |
| `fx2dotnet-package-compat` | `speckit.fx2dotnet-package-compat.record-package-status` | Record chunk result in package-updates.md |
| `fx2dotnet-multitarget` | `speckit.fx2dotnet-multitarget.add-target-frameworks` | Add TFM entries to a project file |
| `fx2dotnet-multitarget` | `speckit.fx2dotnet-multitarget.validate-api-gaps` | Identify API gaps introduced by new TFMs |
| `fx2dotnet-multitarget` | `speckit.fx2dotnet-multitarget.record-multitarget-state` | Write multitarget phase state to project file |
| `fx2dotnet-web-route-inventory` | `speckit.fx2dotnet-web-route-inventory.inventory-routes` | Extract route table from a legacy web project |
| `fx2dotnet-web-route-inventory` | `speckit.fx2dotnet-web-route-inventory.inventory-handlers` | Extract HTTP handlers from a legacy web project |
| `fx2dotnet-web-route-inventory` | `speckit.fx2dotnet-web-route-inventory.inventory-modules` | Extract HTTP modules from a legacy web project |
| `fx2dotnet-web-migration` | `speckit.fx2dotnet-web-migration.scaffold-core-host` | Scaffold new ASP.NET Core host project side-by-side |
| `fx2dotnet-web-migration` | `speckit.fx2dotnet-web-migration.port-routes` | Port legacy routes to the new Core host |
| `fx2dotnet-web-migration` | `speckit.fx2dotnet-web-migration.validate-web-host` | Validate the new host builds and endpoints are preserved |
| `fx2dotnet-orchestrator` | `speckit.fx2dotnet-orchestrator.start` | Start a new end-to-end migration workflow |
| `fx2dotnet-orchestrator` | `speckit.fx2dotnet-orchestrator.resume` | Resume a workflow from last checkpoint |
| `fx2dotnet-orchestrator` | `speckit.fx2dotnet-orchestrator.show-status` | Display current phase and per-project status |
| `fx2dotnet-orchestrator` | `speckit.fx2dotnet-orchestrator.validate-phase-gates` | Validate all phase gates before proceeding |

---

## State File Ownership

### Ownership Rules

1. A state section has exactly one **owning extension** — it is the only extension permitted to write that section.
2. All other extensions may **read** any state file but must not write a section they do not own.
3. Violations of ownership produce a phase-gate failure.

### Ownership Matrix

| State File / Section | Owner Extension | Consumers |
|---|---|---|
| `.fx2dotnet/plan.md` — full file | `fx2dotnet-orchestrator` | All phase extensions (read-only) |
| `.fx2dotnet/plan.md` — `## Per-Project Phase Matrix` | `fx2dotnet-orchestrator` | All phase extensions (read-only) |
| `.fx2dotnet/analysis.md` — full file | `fx2dotnet-assessment` | `planner`, `sdk-conversion`, `package-compat`, `multitarget`, `web-migration` (read-only) |
| `.fx2dotnet/package-updates.md` — full file | `fx2dotnet-assessment` (initial seed) then `fx2dotnet-package-compat` (execution ledger) | `planner`, `orchestrator` (read-only) |
| `.fx2dotnet/preferences.md` — full file | `fx2dotnet-orchestrator` | `build-fix`, `package-compat`, `multitarget` (read/write scoped sections) |
| `.fx2dotnet/{ProjectStateFile}.md` `## SDK Conversion` | `fx2dotnet-sdk-conversion` | `orchestrator`, `build-fix` (read-only) |
| `.fx2dotnet/{ProjectStateFile}.md` `## Build Fix` | `fx2dotnet-build-fix` | `orchestrator` (read-only); reset on each invocation |
| `.fx2dotnet/{ProjectStateFile}.md` `## Multitarget` | `fx2dotnet-multitarget` | `orchestrator`, `web-migration` (read-only) |
| `.fx2dotnet/{ProjectStateFile}.md` `## Web Migration` | `fx2dotnet-web-migration` | `orchestrator` (read-only) |

---

## Canonical `projectId` Format

- `projectId` = normalized **relative** path from solution root to `.csproj` file.
- Path separator: forward slash (`/`) — normalized on all platforms.
- Example: `src/Web/Web.csproj`
- Display name remains friendly (`Web`) for human readability only and must not be used as a join key.

### Deterministic Project Ordering

1. Assessment produces dependency layers; Layer 1 = leaf projects with no in-solution dependencies.
2. Within each layer, projects are sorted by `projectId` **lexical ascending**.
3. Orchestrator processes layers in ascending order; within a layer order is stable.

### Collision-Safe Project State File Naming

When two or more projects share the same file stem (e.g., two projects named `Web.csproj` in different folders):

1. Compute a short 8-character deterministic hash from the `projectId` string.
2. Append the hash as a suffix: `Web-a1b2c3d4.md`, `Web-f9e8d7c6.md`.
3. Every per-project state file must include both `displayName` and `projectId` in its header.
4. Uniqueness rule: a file stem collision exists when two `projectId` values would produce the same display name after stripping the path prefix and extension.

### Uncertainty Markers

When an extension produces output with low confidence, it must emit:

```markdown
<!-- uncertainty: <field-name> | reason: <explanation> | action: needs-user-confirmation -->
```

Orchestrator reads these markers during phase-gate validation and stops with a user confirmation prompt before continuing.

---

## Phase Gate Contract

A phase gate is satisfied when ALL of the following are true for all projects in scope:

| Phase | Gate Condition |
|---|---|
| Assessment → Planning | `analysis.md` exists and all projects have classifications; `package-updates.md` exists |
| Planning → SDK Conversion | `plan.md` exists with non-empty per-project matrix; no open `uncertainty:` markers |
| SDK Conversion → Package Compat | All `needs-sdk-conversion` projects have `conversionStatus: completed` in `## SDK Conversion` |
| Package Compat → Multitarget | All chunks in `package-updates.md` have a terminal result (`completed` or `skipped-approved`) |
| Multitarget → Web Migration | All non-web-host projects have `## Multitarget` status of `completed` or `skipped` |
| Web Migration → Done | All web-host projects have `## Web Migration` status of `completed` or `skipped` |

---

## Cross-File Consistency Rule

`analysis.md`, `plan.md`, `package-updates.md`, and per-project state files must all reference the **same set of `projectId` values**. A missing or extra `projectId` in any file is a phase-gate violation.

---

## Exit Criteria — Satisfied

- [x] Every extension has a stable command surface
- [x] Every state section has a single owning extension
- [x] Cross-extension read/write expectations documented
- [x] `projectId` identity and file-collision rules documented and approved
- [x] Uncertainty markers and phase gate expectations defined
