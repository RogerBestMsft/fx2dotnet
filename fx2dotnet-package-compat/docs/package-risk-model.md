# Package Risk Model

Risk model used by the fx2dotnet Package Compatibility phase to order and gate package-update execution.

## Risk Levels

| Level | Meaning | Execution Behavior |
|---|---|---|
| low | Straightforward compatible version upgrade | Can be batched with related low-risk packages |
| medium | Major version change or likely minor API adjustments | Smaller chunk, validate carefully after build |
| high | Breaking API changes, behavioral differences, or significant config impact | Isolate in its own chunk or with tightly related packages |
| blocking | No compatible version exists or replacement requires architecture change | Stop and require user decision |

## Chunk Ordering

1. Low-risk chunks first
2. Medium-risk chunks next
3. High-risk chunks after that
4. Blocking chunks last and isolated

## Substitution Rules

When a package card recommends `replace-with:{alternative}`:
- Treat as at least `high` risk.
- If `stop_on_risky_substitution: true`, require user approval before applying.
- Record the rationale in `package-updates.md`.

## EF6 Exception

`EntityFramework` 6.x is not treated as a package needing upgrade. It is retained as-is per EF6 policy.
