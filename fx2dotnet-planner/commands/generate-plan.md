---
description: "Synthesize assessment output into an ordered, phased migration plan written to plan.md"
---

# Generate Plan

Consume the assessment findings — project classifications, dependency layers, package compatibility cards, unsupported libraries, and out-of-scope items — and synthesize them into a structured, actionable migration plan in `.fx2dotnet/plan.md`.

## Constraints

- DO NOT read state files directly — all data comes from the assessment content passed by the orchestrator or from subagent delegation.
- DO NOT classify projects — use the classifications provided in the assessment.
- DO NOT edit any project files, run builds, or invoke conversion agents.
- Ground all sequencing decisions in the assessment's compatibility cards — do NOT re-analyze NuGet metadata.
- All project paths in the plan MUST be relative to the solution directory.

## User Input

$ARGUMENTS

This command is typically called by the orchestrator with inline assessment content. In standalone use, provide the solution path; the command will read `analysis.md` and `package-updates.md`.

## Steps

### Step 1: Load Assessment Data

Read `.fx2dotnet/analysis.md` and `.fx2dotnet/package-updates.md` using the `read` tool (or accept assessment content inline from the orchestrator).

Extract:
- Project classifications (SDK-style status, web host classification, confidence, evidence per project)
- Dependency layers (topological order)
- Compatibility cards (current version, target support, minimum compatible version, legacy flags)
- Unsupported libraries and out-of-scope items

### Step 2: Map Project Actions

Assign an action to each project based on the provided classifications:

| Action | Condition |
|---|---|
| `skip-already-sdk` | Project is already SDK-style |
| `needs-sdk-conversion` | Legacy format, not a web-app-host |
| `web-app-host` | Web application host → handled in Phase 6 |
| `uncertain-web` | Assessment marked as `uncertain` → flag for user confirmation |
| `windows-service` | Contains `ServiceBase` or TopShelf usage |

Projects can have both `needs-sdk-conversion` and `windows-service` actions.

### Step 3: Identify Web Migration Candidates

- If exactly one `web-app-host` project: record it as the ASP.NET Core migration candidate.
- If multiple: list all and flag that user must choose or confirm order.
- If none: note that Phase 6 may be skippable.

### Step 4: Resolve Unsupported and Out-of-Scope Packages

For every unsupported library and out-of-scope item, produce a concrete recommended resolution. Do NOT leave items as passive lists. Decide:
- Replace with: `{alternative package}` at `{version}`
- Remove: no replacement available (feature must be re-implemented)
- Retain as-is: compatible with target but flagged for review
- Defer: post-migration action required

### Step 5: Build Package Update Chunks

Group package updates into ordered, minimal-risk chunks:
- Each chunk should contain at most `{config.planning.max_packages_per_chunk}` packages.
- Group packages that are logically related (same framework, same feature area) into the same chunk.
- Order chunks: lower-risk packages first, higher-risk and blocking packages last.
- Blocking packages must be in their own chunk.
- Each chunk must include: chunk ID, description, packages with target versions, risk level, and rollback notes.

### Step 6: Produce Open Questions

If any classification is `uncertain-web`, any unsupported library has no clear resolution, or multiple web-app-hosts exist: produce an `## Open Questions` section listing each item with a clear prompt for user decision.

If `stop_on_blocking_packages: true` and blocking packages exist: stop and ask for user approval before completing the plan.

### Step 7: Write plan.md

Write or update `.fx2dotnet/plan.md` using the `edit` tool with:
- Progress table (all phases as `not-started` initially)
- Metadata block (`lastCompletedPhase: "none"`)
- Per-Project Phase Matrix (all projects from `projectId` set, all phases `not-started`)
- Project Summary section (SDK conversion order by layer, web migration candidate, chunk summary)
- Open Questions section (if any)
- Decisions & Notes section

Also update `.fx2dotnet/package-updates.md` with the `## Chunked Update Queue` section (ordered chunks with risk levels).

### Step 8: Confirm

Report:
- Number of projects needing SDK conversion (and layer order)
- Number of package update chunks
- Web migration candidate (if identified)
- Number of open questions requiring user input

## Domain Policies

### EF6 Retention Policy

When Entity Framework 6 is present (detected by `EntityFramework` package reference ≥ 6.x):
- Do NOT recommend upgrading to EF Core.
- Do NOT include EF6 packages in the upgrade chunk queue.
- Mark EF6 as `retain-as-is` with a note: "EF6 is supported on modern .NET. Retain for now; EF Core migration is a separate post-modernization activity."
- See `docs/ef6-migration-policy.md` for full policy details.

### Windows Service Migration Policy

When a project is classified as `windows-service`:
- Add `windows-service` action in addition to any necessary SDK conversion action.
- Note in the plan that the multitarget phase will replace `System.ServiceProcess.ServiceBase` with `BackgroundService` from `Microsoft.Extensions.Hosting` and `Microsoft.Extensions.Hosting.WindowsServices`.
- See `docs/windows-service-migration.md` for full policy details.
