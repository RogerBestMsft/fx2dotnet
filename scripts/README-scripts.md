# Release Scripts

These scripts implement the packaging, catalog, installation, and validation workflow for the fx2dotnet Spec-Kit extension suite.

## Core Commands

- `pwsh ./scripts/validate-extensions.ps1`
  - Validates all extension manifests, command paths, config templates, cross-extension command dependencies, and hook registrations.
- `pwsh ./scripts/build-mcp.ps1 -Configuration Release`
  - Builds the local `Swick.Mcp.Fx2dotnet` runtime used by the MCP-dependent extensions.
- `pwsh ./scripts/stage-artifacts.ps1 -Configuration Release`
  - Copies local runtime artifacts into each extension directory according to the per-extension artifact manifests.
- `pwsh ./scripts/package-extension.ps1 -ExtensionId fx2dotnet-assessment`
  - Produces a ZIP package and `.sha256` checksum in `releases/`.
- `pwsh ./scripts/generate-catalog.ps1 -InstallAllowed -IncludeCommunityMirror`
  - Updates the internal catalog plus the optional community mirror.

## Install and Removal

- `pwsh ./scripts/deploy-extensions.ps1 -ProjectDir C:\path\to\project -Version 1.0.0`
  - Installs the suite into a Spec-Kit project from the configured catalogs.
- `pwsh ./scripts/deploy-extensions.ps1 -ProjectDir C:\path\to\project -LocalSourceRoot C:\RogerBestMSFT\fx2dotnet`
  - Installs the suite from the local source tree using `specify extension add --dev`.
- `pwsh ./scripts/remove-extensions.ps1 -ProjectDir C:\path\to\project -KeepConfig`
  - Removes the suite in reverse dependency order.

## Post-Install Validation

- `pwsh ./scripts/smoke-test.ps1 -ProjectDir C:\path\to\project`
  - Checks installed manifests, command files, generated config files, and bundled runtime artifacts.

## Line Endings

- The repository enforces `LF` for shell scripts via [/.gitattributes](.gitattributes) (`*.sh text eol=lf`).
- If Git reports `LF would be replaced by CRLF` while adding `.sh` files on Windows, re-normalize and restage after pulling latest `.gitattributes`.
