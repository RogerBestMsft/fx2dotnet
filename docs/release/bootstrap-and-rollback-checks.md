# Bootstrap And Rollback Checks

This document defines the WI-19 install-time validation and rollback contract.

## Bootstrap Checks

Run these checks immediately after install and before first command execution:

| Check | Method | Failure handling |
|---|---|---|
| Manifest present | Confirm `extension.yml` exists in installed extension root | Roll back the extension |
| Command files present | Validate every `provides.commands[].file` path | Roll back the extension |
| Config copy present | Validate each `provides.config[].name` file exists | Roll back the extension |
| Runtime assets present | For extensions that require `Swick.Mcp.Fx2dotnet`, verify `artifacts/` exists | Roll back the extension |
| Hook registration valid | Confirm hook commands resolve to installed commands | Roll back the extension |
| Registry visibility | Confirm `specify extension list` reports the extension | Roll back the extension |

## Diagnostics To Capture

- Extension ID and version
- Installed path
- Missing file or invalid registration details
- Whether the failure happened before or after config generation
- Whether runtime artifacts were expected

## Partial Install Rollback Rules

Rollback is required when any bootstrap check fails after extraction or registration.

1. Remove the partially installed extension.
2. Preserve config only if the install reached config generation and the operator explicitly asks to keep it.
3. If a suite install is in progress, stop at the first failed extension and remove any extensions installed later in the same transaction.
4. Leave previously stable dependencies in place unless they were reinstalled as part of the same transaction.

## Recovery Paths

- Retry from the same version after fixing packaging or catalog metadata.
- Reinstall the previous known-good ZIP from the release archive.
- Switch to a local `--dev` install for investigation if release packaging is suspect.

## Testability

- `scripts/smoke-test.ps1` covers installed-file and runtime-asset checks.
- `scripts/validate-extensions.ps1` covers pre-release manifest and hook validation.
- Release review must include one install, one remove, and one reinstall cycle with config preservation.
