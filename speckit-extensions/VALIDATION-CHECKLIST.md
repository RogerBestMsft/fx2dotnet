# Validation Checklist

Use this checklist after creating or updating any extension in this folder.

## Cross-Extension Checks

| Check | Description |
|---|---|
| Required files | `extension.yml`, `README.md`, `LICENSE`, and `.gitignore` are present for every extension. |
| Schema version | `schema_version: "1.0"` is present in every `extension.yml`. |
| ID pattern | `extension.id` matches `^[a-z0-9-]+$`. |
| Version format | `extension.version` uses `X.Y.Z` exactly. |
| Command name pattern | Each `provides.commands[].name` matches `^speckit\.[a-z0-9-]+\.[a-z0-9-]+$`. |
| Command file exists | Each `provides.commands[].file` path resolves to an existing markdown file, including shared agent files under `agents/`. |
| MCP correctness | Only `fx-assessment` and `fx-sdk-conversion` declare `requires.tools`, and both declare both MCP servers as required. |
| Skill guidance present | Command bodies for `fx-assessment`, `fx-migration-planner`, `fx-multitarget`, `fx-aspnet-web`, and `fx-build-fix` include conditional skill guidance. |
| Non-invasive | `git diff --name-only` against the branch baseline shows only new files under `speckit-extensions/`. |
| Unique command names | No two extensions share a command name. |

## Per-Extension Verification Matrix

| Extension ID | Command | Required files | Schema | ID | Version | Command pattern | Command file | MCP | Skill guidance |
|---|---|---|---|---|---|---|---|---|---|
| `dotnet-fx-migration` | `speckit.dotnet-fx-migration.run` | yes | yes | yes | yes | yes | yes | not applicable | not applicable |
| `fx-assessment` | `speckit.fx-assessment.run` | yes | yes | yes | yes | yes | yes | yes | yes |
| `fx-migration-planner` | `speckit.fx-migration-planner.plan` | yes | yes | yes | yes | yes | yes | not applicable | yes |
| `fx-sdk-conversion` | `speckit.fx-sdk-conversion.convert` | yes | yes | yes | yes | yes | yes | yes | not applicable |
| `fx-package-compat` | `speckit.fx-package-compat.migrate` | yes | yes | yes | yes | yes | yes | not applicable | not applicable |
| `fx-multitarget` | `speckit.fx-multitarget.migrate` | yes | yes | yes | yes | yes | yes | not applicable | yes |
| `fx-aspnet-web` | `speckit.fx-aspnet-web.migrate` | yes | yes | yes | yes | yes | yes | not applicable | yes |
| `fx-build-fix` | `speckit.fx-build-fix.fix` | yes | yes | yes | yes | yes | yes | not applicable | yes |
| `fx-route-inventory` | `speckit.fx-route-inventory.scan` | yes | yes | yes | yes | yes | yes | not applicable | not applicable |
| `fx-project-detector` | `speckit.fx-project-detector.classify` | yes | yes | yes | yes | yes | yes | not applicable | not applicable |

## Manual Validation Steps

1. Confirm no existing files outside `speckit-extensions/` were modified.
2. Confirm each extension folder contains only additive packaging artifacts.
3. Confirm all manifests parse as valid YAML.
4. Confirm all command paths resolve to the intended shared agent markdown under `agents/`.
5. Confirm README files for delegated-only extensions state that they are intended for orchestrator delegation rather than direct manual use.

## CLI Dry Run

```shell
specify extension validate speckit-extensions/dotnet-fx-migration
specify extension validate speckit-extensions/fx-assessment
specify extension validate speckit-extensions/fx-migration-planner
specify extension validate speckit-extensions/fx-sdk-conversion
specify extension validate speckit-extensions/fx-package-compat
specify extension validate speckit-extensions/fx-multitarget
specify extension validate speckit-extensions/fx-aspnet-web
specify extension validate speckit-extensions/fx-build-fix
specify extension validate speckit-extensions/fx-route-inventory
specify extension validate speckit-extensions/fx-project-detector
```