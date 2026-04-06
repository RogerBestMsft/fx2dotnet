# Artifact Packaging Model

This document defines the packaging contract for WI-16.

## Packaging Principles

- Each extension ships as an independent ZIP with archive-root contents ready to extract into `.specify/extensions/<extension-id>/`.
- Packaging is driven by the per-extension manifests in `packaging/artifact-manifests/`.
- Local runtime bundling is limited to the in-repo `Swick.Mcp.Fx2dotnet` binary. External MCP services remain declared as dependencies, not bundled binaries.
- All release assets include a SHA-256 checksum file.

## Source-To-Artifact Mapping

| Extension set | Source content | Bundled runtime assets | Target ZIP layout |
|---|---|---|---|
| All extensions | `extension.yml`, `commands/`, `docs/`, config template | None unless explicitly listed in artifact manifest | Archive root |
| Support-core, classifier, assessment, build-fix | `scripts/` when present | None for support-core, classifier, build-fix | Archive root |
| Assessment, SDK conversion, package compat | Extension files plus staged `artifacts/bin/fx2dotnet/<Configuration>/` | `Swick.Mcp.Fx2dotnet` build output | `artifacts/bin/fx2dotnet/<Configuration>/` inside ZIP |

## Runtime Path Resolution Rules

- Build local runtime once into `artifacts/bin/fx2dotnet/<Configuration>/`.
- Stage runtime assets into extension folders with `scripts/stage-artifacts.ps1`.
- Package extensions only after staging succeeds.
- Treat missing staged runtime assets as a packaging failure for MCP-dependent extensions.

## ZIP Integrity Metadata

- ZIP file name: `fx2dotnet-<extension-id>-<version>.zip`
- Checksum file: `fx2dotnet-<extension-id>-<version>.zip.sha256`
- Hash algorithm: `sha256`

## Release Outputs

- Extension ZIPs in `releases/`
- SHA-256 checksum files next to each ZIP
- Updated `catalogs/catalog.json`
- Optional `catalogs/community-catalog.json`

The canonical machine-readable definition is the manifest set in `packaging/artifact-manifests/`. The packaging scripts consume those manifests directly.
