# Verification And Release Gates

This document defines WI-21.

## Automated CI Gates

| Gate | Mechanism | Required for release |
|---|---|---|
| Manifest validation | `scripts/validate-extensions.ps1` | Yes |
| MCP build | `scripts/build-mcp.ps1 -Configuration Release` | Yes |
| Runtime staging | `scripts/stage-artifacts.ps1 -Configuration Release` | Yes |
| Extension packaging | `scripts/package-extension.ps1` across all artifact manifests | Yes |
| Catalog generation | `scripts/generate-catalog.ps1` | Yes |
| NuGet server build | `.github/workflows/ci.yml` pack job | Yes |

## Functional Release Gates

| Gate | Evidence |
|---|---|
| Install smoke test | Successful run of `scripts/smoke-test.ps1` against a clean Spec-Kit project |
| Command execution test | Manual launch of the installed commands from orchestrator entrypoints |
| Catalog validation | Generated catalog JSON opens cleanly and contains correct metadata |
| Dry run against sample solution | Orchestrator reaches expected checkpoints without contract violations |
| Same-name project collision test | Distinct per-project state outputs for different `projectId` values sharing a file stem |
| Interrupt and resume test | Resume continues from exact `projectId` plus phase checkpoint |
| Cross-file `projectId` consistency test | `analysis.md`, `plan.md`, `package-updates.md`, and per-project files contain the same canonical inventory |
| Rollback and reinstall test | Install, remove, and reinstall succeeds with config preservation behavior verified |

## Human Release Review

1. Confirm the release tag matches the extension being published.
2. Review ZIP contents against the artifact manifest for that extension.
3. Review checksum output.
4. Review generated catalog entry metadata and download URL.
5. Review release notes, compatibility matrix, and rollback guidance.

## Release Stop Conditions

- Any manifest validation error
- Any missing staged runtime asset for MCP-dependent extensions
- Any package checksum mismatch
- Any failed install smoke test
- Any unresolved `projectId` collision or resume-continuity defect
