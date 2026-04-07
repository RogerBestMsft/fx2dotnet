---
description: "Bump spec-kit extension versions. Use when: version bump, release prep, update extension.yml versions"
---

Bump all spec-kit extension.yml files to version ${{version}}.

On Windows, run `spec-kit/scripts/bump-version.ps1 -Version ${{version}}`.
On macOS/Linux, run `spec-kit/scripts/bump-version.sh ${{version}}`.

If a schema version update is also needed, append the schema version flag (major.minor format, e.g. 1.0):

On Windows: `spec-kit/scripts/bump-version.ps1 -Version ${{version}} -SchemaVersion <major.minor>`
On macOS/Linux: `spec-kit/scripts/bump-version.sh ${{version}} --schema-version <major.minor>`
