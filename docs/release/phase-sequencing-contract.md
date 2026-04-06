# Phase Sequencing Contract

This document finalizes WI-20.

## Canonical Phase Order

1. Assessment
2. Planning
3. SDK Conversion
4. Package Compatibility
5. Multitarget
6. Web Migration

Support behavior:

- `fx2dotnet-build-fix` may run inside phases 3 through 6, but it does not advance phase state on its own.
- `fx2dotnet-web-route-inventory` is an invoked dependency of Web Migration and runs only for projects classified as web hosts.

## Per-Project Ordering

- Use dependency layer index ascending.
- Within a layer, use lexical `projectId` ascending.
- No project may advance to the next phase while another eligible project in the same layer remains `in-progress` for the current phase.
- No project in Layer `N + 1` may start a phase while any Layer `N` project remains `in-progress`.

## Fan-Out And Fan-In Rules

- Fan-out: execute the current phase for each eligible project in the active layer.
- Fan-in: hold advancement until each project in the active layer is `completed`, `blocked`, or `skipped` with rationale.
- `blocked` prevents automatic phase advancement.
- `skipped` requires explicit rationale in the per-project ledger.

## Resume Pointer Format

Resume state is keyed by `projectId` plus phase.

```json
{
  "phase": "sdk-conversion",
  "projectId": "src/Web/Web.csproj",
  "layer": 2,
  "status": "in-progress",
  "updatedAt": "2026-04-03T18:00:00Z"
}
```

## Completion Signaling

- A phase is complete only when required state files or state sections exist and the project ledger marks the project `completed`.
- Orchestrator writes the authoritative checkpoint to `.fx2dotnet/plan.md`.
- Phase extensions never infer completion from log output alone.

## Failure Escalation

- `blocked` state requires a human-visible blocker summary.
- Build-fix retries are bounded inside the phase command.
- Resume always returns to the exact `projectId` plus phase checkpoint, never to a phase-only bookmark.
- Cross-file `projectId` mismatches are phase-gate violations and must stop orchestration.
