# Phase Status Matrix Schema

The orchestrator stores workflow state in `.fx2dotnet/plan.md` using a per-project matrix keyed by `projectId`.

## Columns

| Column | Meaning |
|---|---|
| `projectId` | Canonical normalized solution-relative project path |
| `displayName` | Friendly project name |
| `Assessment` | `not-started|in-progress|completed|blocked|skipped` |
| `Planning` | `not-started|in-progress|completed|blocked|skipped` |
| `SDK Conversion` | `not-started|in-progress|completed|blocked|skipped` |
| `Package Compat` | `not-started|in-progress|completed|blocked|skipped` |
| `Multitarget` | `not-started|in-progress|completed|blocked|skipped` |
| `Web Migration` | `not-started|in-progress|completed|blocked|skipped` |
| `Last Updated` | ISO-8601 timestamp |
| `Notes` | Short status note |

## Checkpoint Format

A resume checkpoint is the first row in stable phase order where the current phase status is `not-started`, `in-progress`, or `blocked`.
