# Catalog Install Flow

This document defines the WI-18 catalog contract and install flow.

## Catalog Topology

- Internal catalog: `catalogs/catalog.json`
  - `install_allowed: true`
  - Source of truth for managed installs
- Optional community mirror: `catalogs/community-catalog.json`
  - `install_allowed: false`
  - Discovery-only mirror for public browsing

## Catalog Entry Rules

- Generate entries from `extension.yml` plus release metadata.
- Use per-extension release tags: `fx2dotnet-<extension-id>-v<version>`.
- Derive `download_url` from the GitHub release asset for that tag.
- Preserve required command and tool metadata from the manifest.

## User Install Walkthrough

1. Add the internal catalog to the target Spec-Kit project.

```yaml
catalogs:
  - name: fx2dotnet-internal
    url: https://github.com/RogerBestMSFT/fx2dotnet/raw/main/catalogs/catalog.json
    install_allowed: true
```

2. Search the catalog.

```powershell
specify extension search fx2dotnet
```

3. Install a released extension.

```powershell
specify extension add fx2dotnet-orchestrator --version 1.0.0
```

4. Install the full suite in dependency order.

```powershell
pwsh ./scripts/deploy-extensions.ps1 -ProjectDir C:\path\to\project -Version 1.0.0
```

5. Validate the installation.

```powershell
pwsh ./scripts/smoke-test.ps1 -ProjectDir C:\path\to\project
```

## Local Developer Install Flow

Use local source installs during extension authoring:

```powershell
pwsh ./scripts/deploy-extensions.ps1 -ProjectDir C:\path\to\project -LocalSourceRoot C:\RogerBestMSFT\fx2dotnet
```

This path uses `specify extension add --dev <extension-path>` for each extension.

## Catalog Update Automation

- CI regenerates the internal catalog after packaging a tagged release.
- The same generator can emit the optional community catalog in the same run.
- Catalog changes should be committed only after release assets and checksums are published successfully.
