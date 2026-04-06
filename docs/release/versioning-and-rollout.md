# Versioning And Rollout

This document defines WI-22.

## Versioning Policy

- Each extension uses independent SemVer.
- A patch version changes packaging, fixes manifest errors, or corrects non-breaking command behavior.
- A minor version adds commands, docs, or optional config fields without breaking existing installs.
- A major version changes command contracts, required config shape, state contract expectations, or release compatibility assumptions.

## Compatibility Matrix Template

| Release date | Extension | Version | Minimum support-core | Compatible orchestrator | Notes |
|---|---|---|---|---|---|
| YYYY-MM-DD | fx2dotnet-assessment | X.Y.Z | X.Y.Z | X.Y.Z | Fill in validation notes |

Maintain one row per released extension version.

## Release Notes Template

```markdown
# fx2dotnet-<extension-id> v<version>

## What Changed
- 

## Compatibility
- Minimum `fx2dotnet-support-core`:
- Compatible orchestrator versions:

## Upgrade Notes
- 

## Rollback Guidance
- Previous stable version:
- Catalog action if rollback is needed:
```

## Release Runbook

1. Update `extension.yml` version for the target extension.
2. Validate the suite and package the target extension.
3. Tag the release as `fx2dotnet-<extension-id>-v<version>`.
4. Let release CI publish the ZIP and checksum.
5. Regenerate and commit catalog entries.
6. Publish release notes and update the compatibility matrix.

## Upgrade Guidance

- Prefer rolling forward to the next compatible patch when possible.
- If a version introduces new required config, document the migration in release notes and provide defaults where possible.
- Validate orchestrator and support-core compatibility before promoting a phase extension.

## Downgrade Guidance

- Remove the current extension version.
- Reinstall the previous known-good ZIP or catalog version.
- Preserve config when the config schema remains compatible; otherwise restore from backup.

## Rollback Runbook

1. Remove the broken version from the internal catalog.
2. Re-point affected installs to the previous stable version.
3. Publish corrected release notes explaining the rollback trigger.
4. Ship a patch release only after the failed gate is reproduced and fixed.
