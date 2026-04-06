# State Contract

This document defines the structure, ownership, and validation rules for all `.fx2dotnet/` state files produced and consumed by the fx2dotnet extension suite.

## Overview

All migration state lives under `{solutionDir}/.fx2dotnet/`. The state directory is created by the first phase command that writes to it. No command may create this directory via shell; all writes use the `edit` tool.

## File Map

```
{solutionDir}/.fx2dotnet/
├── plan.md                         # Orchestrator state + migration plan (owner: fx2dotnet-orchestrator)
├── analysis.md                     # Assessment findings (owner: fx2dotnet-assessment)
├── package-updates.md              # Package compatibility ledger (owner: fx2dotnet-assessment → fx2dotnet-package-compat)
├── preferences.md                  # Continuation preferences (owner: fx2dotnet-orchestrator)
└── {ProjectStateFile}.md           # Per-project phase state (multiple owners by section)
```

## plan.md

**Owner**: `fx2dotnet-orchestrator`  
**Consumers**: All phase extensions (read-only)

### Required Sections

```markdown
# Migration Plan

**Solution**: {path}
**Target Framework**: {tfm}
**Created**: {ISO-8601}
**Last Updated**: {ISO-8601}

## Progress

| Phase | Status | Completed | Notes |
|-------|--------|-----------|-------|

## Metadata

- `lastCompletedPhase`: {phase-name | "none"}
- `packageCompatStatus`: {not-started | in-progress | completed}
- `multitargetStatus`: {not-started | in-progress | completed}
- `aspnetMigrationStatus`: {not-started | in-progress | completed}

## Per-Project Phase Matrix

| projectId | displayName | Assessment | Planning | SDK Conversion | Package Compat | Multitarget | Web Migration | Last Updated | Notes |
```

### Phase Status Values

`not-started` | `in-progress` | `completed` | `blocked` | `skipped`

## analysis.md

**Owner**: `fx2dotnet-assessment`  
**Consumers**: `planner`, `sdk-conversion`, `package-compat`, `multitarget`, `web-migration` (read-only)

### Required Sections

```markdown
# Assessment Report

**Date**: {date}
**Solution**: {path}
**Assessed Projects**: {count}

## Project Inventory

| projectId | Project | Framework | Type | Location |

## Framework Inventory

## Dependency Layers

### Layer 1 (Leaves — no internal dependencies)
### Layer 2 ...

## Project Classifications

### {ProjectName}
- **Type**: {Class Library | Web Application | Console | Windows Service}
- **SDK-style Status**: {Candidate | Already SDK-style | Not applicable}
```

## package-updates.md

**Initial seed owner**: `fx2dotnet-assessment`  
**Execution ledger owner**: `fx2dotnet-package-compat`

### Required Sections

```markdown
# Package Updates

## Compatibility Findings

## Chunked Update Queue

### Chunk {n}: {description}
- Status: {pending | in-progress | completed | skipped-approved | blocked}

## Execution Log
```

## {ProjectStateFile}.md

Each project gets its own state file. File name is derived from the display project name; if a collision exists, a short hash suffix is appended (see WI-02).

### Section Ownership

| Section | Owner |
|---|---|
| `## SDK Conversion` | `fx2dotnet-sdk-conversion` |
| `## Build Fix` | `fx2dotnet-build-fix` (reset each invocation) |
| `## Multitarget` | `fx2dotnet-multitarget` |
| `## Web Migration` | `fx2dotnet-web-migration` |

### File Header (Required)

```markdown
# {displayName} Migration State

**projectId**: {normalized-relative-path}
**displayName**: {friendly-name}
**solutionDir**: {absolute-path}
```

## Uncertainty Markers

Any extension producing low-confidence output must emit an uncertainty marker in the relevant state section:

```markdown
<!-- uncertainty: {field} | reason: {explanation} | action: needs-user-confirmation -->
```

The orchestrator reads these markers during phase-gate validation and stops with a user confirmation prompt before continuing.

## File Operations Policy

- Use the `read` tool to check whether a file exists. If the read fails, the file does not exist.
- Use the `edit` tool to create and update state files.
- Do NOT use shell commands (`Test-Path`, `Get-Item`, etc.) for file existence checks.
- State files are plain Markdown and can be inspected by the user at any time.
