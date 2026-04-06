# Artifact Packaging Model

The packaging layer uses one artifact manifest per extension in `packaging/artifact-manifests/`.

## Rules

- Each manifest declares the extension source directory, ZIP root, included content, and runtime assets.
- Local runtime bundling is limited to `Swick.Mcp.Fx2dotnet` for `fx2dotnet-assessment`, `fx2dotnet-sdk-conversion`, and `fx2dotnet-package-compat`.
- The packaging flow is deterministic: validate manifests, build local runtime once, stage runtime assets from repo output into the target extensions, then package each extension from its manifest.
- ZIPs contain extension contents at the archive root so Spec-Kit extracts directly into `.specify/extensions/<extension-id>/`.
- Every packaged ZIP gets a `.sha256` companion file.

## Standard Layout

```text
fx2dotnet-<extension>-<version>.zip
|- extension.yml
|- commands/
|- docs/
|- scripts/                      # only when needed by the extension
|- artifacts/bin/fx2dotnet/...   # only for local runtime bundles
`- <extension>-config.template.yml
```

## Runtime Path Resolution

- Build output source: `artifacts/bin/fx2dotnet/<Configuration>/`
- Staged runtime target: `<extension>/artifacts/bin/fx2dotnet/<Configuration>/`
- Package-time include path: `artifacts/`

## Integrity Metadata

- Packaging manifest checksum algorithm: `sha256`
- Release asset checksum file format: `<sha256>  <zip-file-name>`
