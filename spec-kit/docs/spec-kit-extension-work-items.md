# spec-kit Extension Work Items

## Summary

Add-only spec-kit community extension packaging for the fx2dotnet migration plugin. Four new files at the repo root (`extension.yml`, `CHANGELOG.md`, `LICENSE`, `.extensionignore`) were added. The extension root is the repo root so existing `agents/` paths require no `../` traversal. No existing files are modified.

**License**: MIT (2026)  
**Extension ID**: `fx2dotnet-migration`  
**Version**: `0.1.0`

## Current Status (2026-03-31)

| Work Item | Status | Notes |
|---|---|---|
| WI-001 | Completed | CLI shape confirmed with `specify extension --help`; no `specify extension validate` command exists in this CLI version. |
| WI-002 | Completed | `extension.yml` added with all 7 command registrations. |
| WI-003 | Completed | `CHANGELOG.md` added with `0.1.0` entry and command additions. |
| WI-004 | Completed | `LICENSE` added as MIT (2026, RogerBestMSFT). |
| WI-005 | Completed | `.extensionignore` added with expected exclusions. |
| WI-006 | Pending | Updated below to use checks that exist in the current CLI. |
| WI-007 | Pending | Must run from a spec-kit project root containing `.specify/`. |

---

## Dependency Order

```
WI-001 (CLI check)
  └── WI-002 (extension.yml)
        └── WI-006 (validate manifest)
              └── WI-007 (test local install)

WI-003 (CHANGELOG.md) ─┐
WI-004 (LICENSE)       ─┤  parallel — no blockers
WI-005 (.extensionignore) ─┘
```

---

## Work Items

### WI-001 — Verify spec-kit CLI and `extension.yml` schema

**Type**: Prerequisite  
**Blocks**: WI-002

**Goal**: Confirm the `specify` CLI is available and capture the exact `extension.yml` YAML schema before the manifest is authored.

**Steps**:
1. Run `specify --version` to confirm the CLI is installed.
2. Run `specify extension --help` and `specify extension add --help` to capture supported extension-management commands in this CLI version.
3. Confirm that `.agent.md` files are accepted as `provides.commands[].file` entries by validating paths and testing install from a spec-kit host project.
4. Record the minimum `speckit_version` value required for the command features used.

**Output**: Confirmed schema field names and `speckit_version` constraint for use in WI-002.

---

### WI-002 — Create `extension.yml`

**Type**: New file  
**Depends on**: WI-001  
**Blocks**: WI-006

**Goal**: Spec-kit extension manifest registering all 7 commands against the existing agent files.

**File**: `extension.yml` (repo root)

**Sources**:
- `README.md` — prerequisites, overview text, phase summaries, migration flow terminology
- `plugin.json` — product naming and relationship to the current plugin
- `.mcp.json` — prerequisite information for MCP-backed tooling
- `.github/copilot-instructions.md` — architecture overview (orchestrator, phase agents, skills, MCP server roles), agent file conventions (YAML frontmatter fields, handoffs, state-file path), and code-change constraints (smallest-possible diff, no unconfirmed NuGet adds)

**Required fields**:

| Field | Value |
|---|---|
| `schema_version` | `"1.0"` |
| `id` | `fx2dotnet-migration` |
| `version` | `0.1.0` |
| `name` | `fx2dotnet Modernization` |
| `description` | First paragraph of `README.md` (do not paraphrase) |
| `requires.speckit_version` | Range determined in WI-001 |

**Command registrations** (`provides.commands`):

| Command | File (relative to repo root) |
|---|---|
| `speckit.fx2dotnet-migration.orchestrate` | `agents/dotnet-fx-to-modern-dotnet.md` |
| `speckit.fx2dotnet-migration.assessment` | `agents/assessment.agent.md` |
| `speckit.fx2dotnet-migration.planning` | `agents/migration-planner.agent.md` |
| `speckit.fx2dotnet-migration.sdk-conversion` | `agents/sdk-project-conversion.agent.md` |
| `speckit.fx2dotnet-migration.package-compat` | `agents/package-compat-core.agent.md` |
| `speckit.fx2dotnet-migration.multitarget` | `agents/multitarget.agent.md` |
| `speckit.fx2dotnet-migration.web-migration` | `agents/aspnet-framework-to-aspnetcore-web-migration.agent.md` |

**Constraints**:
- Do not add `hooks` or `config` sections unless schema validation requires them.
- Command names must follow the `speckit.{ext-id}.{command}` pattern exactly.
- All file paths must be relative to the repo root with no `../` escapes.

---

### WI-003 — Create `CHANGELOG.md`

**Type**: New file  
**Depends on**: nothing  
**Parallel with**: WI-004, WI-005

**Goal**: Initial release changelog satisfying spec-kit packaging requirements.

**File**: `CHANGELOG.md` (repo root)

**Content**:
- Follow [Keep a Changelog](https://keepachangelog.com) format.
- Single entry: `## [0.1.0] - 2026-03-31`
- Under `### Added`: one line per command, derived from the `description` frontmatter of the corresponding agent file:

| Command | Source description (agent frontmatter) |
|---|---|
| `speckit.fx2dotnet-migration.orchestrate` | From `agents/dotnet-fx-to-modern-dotnet.md` |
| `speckit.fx2dotnet-migration.assessment` | From `agents/assessment.agent.md` |
| `speckit.fx2dotnet-migration.planning` | From `agents/migration-planner.agent.md` |
| `speckit.fx2dotnet-migration.sdk-conversion` | From `agents/sdk-project-conversion.agent.md` |
| `speckit.fx2dotnet-migration.package-compat` | From `agents/package-compat-core.agent.md` |
| `speckit.fx2dotnet-migration.multitarget` | From `agents/multitarget.agent.md` |
| `speckit.fx2dotnet-migration.web-migration` | From `agents/aspnet-framework-to-aspnetcore-web-migration.agent.md` |

---

### WI-004 — Create `LICENSE`

**Type**: New file  
**Depends on**: nothing  
**Parallel with**: WI-003, WI-005

**Goal**: MIT license file required for extension packaging.

**File**: `LICENSE` (repo root)

**Content**: Standard MIT license text.
- Year: `2026`
- Copyright holder: `RogerBestMSFT`

---

### WI-005 — Create `.extensionignore`

**Type**: New file  
**Depends on**: nothing  
**Parallel with**: WI-003, WI-004

**Goal**: Exclude development-only artifacts from the installed or published extension package.

**File**: `.extensionignore` (repo root)

**Patterns to exclude**:
```
src/
fx2dotnet.slnx
global.json
Directory.Build.props
Directory.Build.targets
.github/
spec-kit/
artifacts/
plugin.json
.mcp.json
```

**Shipping assets** (must NOT be excluded): `agents/`, `skills/`, `README.md`, `CHANGELOG.md`, `LICENSE`, `extension.yml`

---

### WI-006 — Validate extension manifest

**Type**: Validation step  
**Depends on**: WI-002  
**Blocks**: WI-007

**Goal**: Confirm packaging inputs are valid for install and all command file paths resolve.

**Steps**:
1. Run `specify check` to verify required tooling is available.
2. Confirm `extension.yml` command names follow `speckit.{ext-id}.{command}` and every `provides.commands[].file` path exists under `agents/`.
3. If any issue is found, update `extension.yml` only.

**Pass criteria**: Tooling checks pass and manifest paths/names are internally consistent.

---

### WI-007 — Test local installation

**Type**: Validation step  
**Depends on**: WI-006

**Goal**: Confirm the extension installs and commands register end-to-end.

**Important context**: `specify extension` commands must run from a spec-kit project root (a directory containing `.specify/`). Running from this repository root fails with: `Not a spec-kit project (no .specify/ directory)`.

**Steps**:
1. Change to a spec-kit host project root (must contain `.specify/`).
2. Run `specify extension add --dev C:\RogerBestMSFT\fx2dotnet`.
3. Run `specify extension list` and confirm `fx2dotnet-migration` appears.
4. Run `specify extension info fx2dotnet-migration` and confirm `speckit.fx2dotnet-migration.orchestrate` and at least one phase command (for example `speckit.fx2dotnet-migration.assessment`) are listed.

**Pass criteria**: Extension listed, orchestration command and at least one phase command confirmed registered.

---

## Decisions

| Topic | Decision |
|---|---|
| Extension root | Repo root — `agents/` is a direct child, no path escapes needed |
| Command file source | Existing files in `agents/` only — no new `commands/` folder |
| Manifest metadata key | `extension.name` (not `display_name`) |
| License | MIT, 2026 |
| Version | `0.1.0` (matches `plugin.json`) |
| Skills in command surface | No — skills are source material only, not registered as commands |
| Architecture/constraints source | `.github/copilot-instructions.md` — used when authoring manifest description, orchestration command context, and README behavioral expectations |
| Extension README | Existing `README.md` at repo root — no modification needed |
| `plugin.json` / `.mcp.json` in package | Excluded via `.extensionignore` |

## Constraints

1. Add-only change set — no edits to any existing tracked file.
2. No changes to agent instructions, skill policies, plugin behavior, or source code.
3. No new migration logic beyond what the existing agents already describe.
4. Community catalog submission is out of scope for this change set.

## Relevant Source Files

These are read-only references; none are modified by the work items above.

- `plugin.json` — version and display name to reuse in `extension.yml`
- `README.md` — description text to reuse; the extension README
- `agents/dotnet-fx-to-modern-dotnet.md` — orchestrate command source
- `agents/assessment.agent.md` — assessment command source
- `agents/migration-planner.agent.md` — planning command source
- `agents/sdk-project-conversion.agent.md` — sdk-conversion command source
- `agents/package-compat-core.agent.md` — package-compat command source
- `agents/multitarget.agent.md` — multitarget command source
- `agents/aspnet-framework-to-aspnetcore-web-migration.agent.md` — web-migration command source
