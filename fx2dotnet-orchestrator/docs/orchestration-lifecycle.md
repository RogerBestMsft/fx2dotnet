# Orchestration Lifecycle

Lifecycle of the fx2dotnet orchestrator from workflow start through resume and completion.

## Phases

1. Assessment
2. Planning
3. SDK Conversion
4. Package Compatibility
5. Multitarget
6. Web Migration
7. Done

## Resume Semantics

Resume works at **project + phase** granularity using `projectId` and the per-project phase matrix in `.fx2dotnet/plan.md`.

## Invariants

- Do not advance to the next phase until current phase gate passes.
- Process projects by dependency layer and lexical `projectId` order.
- Surface blocked state and uncertainty markers immediately.
