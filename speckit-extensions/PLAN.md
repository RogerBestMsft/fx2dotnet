# Spec-Kit Extensions Plan

## Overview

Create one Spec-Kit extension per migration agent. All extension files live in the new
`speckit-extensions/` top-level folder. No existing files are modified, moved, or deleted.

The two MCP servers configured in `.mcp.json` are:

| Key | Package |
|-----|---------|
| `Microsoft.GitHubCopilot.AppModernization.Mcp` | `Microsoft.GitHubCopilot.AppModernization.Mcp@1.0.903-preview1` |
| `Swick.Mcp.Fx2dotnet` | `Swick.Mcp.Fx2dotnet@0.1.0-beta` |

The four skills are:

| Folder | Domain |
|--------|--------|
| `skills/ef6-migration-policy/` | Retain EF6, do not swap to EF Core |
| `skills/systemweb-adapters/` | System.Web adapter bridging |
| `skills/windows-service-migration/` | Replace ServiceBase with BackgroundService |
| `skills/owin-identity/` | OWIN/Katana auth migration |

---

## Hard Constraints

- Do **not** edit, rename, or move any file under `agents/`, `skills/`, `src/`, `.mcp.json`, `plugin.json`, `Directory.Build.*`, `global.json`, or `fx2dotnet.slnx`.
- All new artifacts must be additive and live exclusively under `speckit-extensions/`.
- All extension IDs and command names use only lowercase letters, digits, and hyphens.
- Command names must match the pattern `speckit.{extension-id}.{command}`.
- `extension.version` must be `X.Y.Z` — no `v` prefix, no pre-release suffix.

---

## Repository Layout After Implementation

```
speckit-extensions/
├── PLAN.md                          ← This file
├── VALIDATION-CHECKLIST.md          ← Cross-extension validation
│
├── dotnet-fx-migration/             ← Orchestrator extension
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── run.md
│
├── fx-assessment/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── run.md
│
├── fx-migration-planner/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── plan.md
│
├── fx-sdk-conversion/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── convert.md
│
├── fx-package-compat/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── migrate.md
│
├── fx-multitarget/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── migrate.md
│
├── fx-aspnet-web/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── migrate.md
│
├── fx-build-fix/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── fix.md
│
├── fx-route-inventory/
│   ├── extension.yml
│   ├── README.md
│   ├── LICENSE
│   ├── CHANGELOG.md
│   └── commands/
│       └── scan.md
│
└── fx-project-detector/
    ├── extension.yml
    ├── README.md
    ├── LICENSE
    ├── CHANGELOG.md
    └── commands/
        └── classify.md
```

---

## Agent-to-Extension Matrix

| Agent file | Extension ID | Command | User-invocable | AppModernization MCP | Fx2dotnet MCP | Skills |
|---|---|---|---|---|---|---|
| `dotnet-fx-to-modern-dotnet.md` | `dotnet-fx-migration` | `speckit.dotnet-fx-migration.run` | yes | no (delegates to sub-agents) | no (delegates to sub-agents) | none directly |
| `assessment.agent.md` | `fx-assessment` | `speckit.fx-assessment.run` | yes | all tools (`*`) | all tools (`*`) | ef6-migration-policy, systemweb-adapters, windows-service-migration |
| `migration-planner.agent.md` | `fx-migration-planner` | `speckit.fx-migration-planner.plan` | no | no | no | ef6-migration-policy, systemweb-adapters, windows-service-migration |
| `sdk-project-conversion.agent.md` | `fx-sdk-conversion` | `speckit.fx-sdk-conversion.convert` | yes | `convert_project_to_sdk_style` only | `GetMinimalPackageSet` only | none |
| `package-compat-core.agent.md` | `fx-package-compat` | `speckit.fx-package-compat.migrate` | no | no | no | none |
| `multitarget.agent.md` | `fx-multitarget` | `speckit.fx-multitarget.migrate` | yes | no | no | ef6-migration-policy, systemweb-adapters, windows-service-migration |
| `aspnet-framework-to-aspnetcore-web-migration.agent.md` | `fx-aspnet-web` | `speckit.fx-aspnet-web.migrate` | no | no | no | systemweb-adapters, owin-identity |
| `build-fix.agent.md` | `fx-build-fix` | `speckit.fx-build-fix.fix` | no | no | no | ef6-migration-policy, systemweb-adapters, windows-service-migration |
| `legacy-web-route-inventory.agent.md` | `fx-route-inventory` | `speckit.fx-route-inventory.scan` | no | no | no | none |
| `project-type-detector.agent.md` | `fx-project-detector` | `speckit.fx-project-detector.classify` | no | no | no | none |

---

## Work Items

Items are grouped by extension. Within each extension, the files must exist before validation can run.
Cross-extension items (VALIDATION-CHECKLIST.md, catalog fragment) are at the end.

### WI-01 — `dotnet-fx-migration` extension (Orchestrator)

**Wraps**: `agents/dotnet-fx-to-modern-dotnet.md`

#### WI-01-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "dotnet-fx-migration"
  name: ".NET Framework to Modern .NET Migration"
  version: "0.1.0"
  description: "Orchestrates end-to-end .NET Framework to modern .NET migration via a 7-phase workflow: assessment, planning, SDK conversion, package compat, multitarget, and ASP.NET Core migration."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.dotnet-fx-migration.run"
      file: "commands/run.md"
      description: "Start or resume a full .NET Framework to modern .NET migration for a solution."

tags:
  - "dotnet"
  - "migration"
  - "modernization"
  - "aspnet"
```

#### WI-01-B `commands/run.md`

Frontmatter: no `tools` entry (no direct MCP usage — MCP is consumed by sub-agents).

Body must cover:
- Argument: solution path (`.sln`/`.slnx`) and optional target framework (default `net10.0`).
- Resume semantics: check `.fx2dotnet/plan.md` before initializing fresh state.
- Phase enforcement order identical to the orchestrator agent: Assessment → Planning →
  SDK Conversion → Package Compat → Multitarget → ASP.NET Core Web Migration.
- State file conventions for `.fx2dotnet/plan.md` and per-project `.fx2dotnet/{ProjectName}.md`.
- Completion prompt asking the user to commit, continue without committing, or review manually.
- Note that MCP tools are activated automatically when sub-agent phases run; the orchestrator
  itself does not call MCP tools directly.

#### WI-01-C `README.md`

Describe: purpose, argument hint, phase overview, state files written, and link to parent plugin repo.

#### WI-01-D `LICENSE`

MIT license text, copyright holder `fx2dotnet contributors`.

#### WI-01-E `CHANGELOG.md`

Initial entry: `0.1.0 - Initial release`.

---

### WI-02 — `fx-assessment` extension (Assessment)

**Wraps**: `agents/assessment.agent.md`

#### WI-02-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-assessment"
  name: ".NET Solution Assessment"
  version: "0.1.0"
  description: "Assesses a .NET solution for migration: identifies frameworks, dependencies, routes, and blockers. Classifies projects and audits NuGet package compatibility."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"
  tools:
    - name: "Microsoft.GitHubCopilot.AppModernization.Mcp"
      required: true
    - name: "Swick.Mcp.Fx2dotnet"
      required: true

provides:
  commands:
    - name: "speckit.fx-assessment.run"
      file: "commands/run.md"
      description: "Run a full migration assessment against a .NET solution and write findings to .fx2dotnet/."

tags:
  - "dotnet"
  - "assessment"
  - "migration"
  - "nuget"
```

#### WI-02-B `commands/run.md`

Frontmatter `tools` entries:
```yaml
tools:
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/get_state'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/get_scenarios'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/get_instructions'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/initialize_scenario'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/start_task'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/complete_task'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/get_projects_in_topological_order'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/get_project_dependencies'
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/ComputeDependencyLayers'
  - 'Swick.Mcp.Fx2dotnet/GetMinimalPackageSet'
```

Body must cover:
- Argument: solution path (required).
- Output files written: `.fx2dotnet/analysis.md` and `.fx2dotnet/package-updates.md`.
- Skill activation guidance — conditional, domain-gated:
  - Load `skills/ef6-migration-policy/SKILL.md` when EF6 packages are detected.
  - Load `skills/systemweb-adapters/SKILL.md` when `System.Web` or classic ASP.NET packages are detected.
  - Load `skills/windows-service-migration/SKILL.md` when Windows Service projects are detected.
- Project classification role: SDK-style vs legacy, web host vs library, Windows Service.
- NuGet compatibility audit role: compatibility cards per package, unsupported libs, out-of-scope items.

#### WI-02-C thru WI-02-E: `README.md`, `LICENSE`, `CHANGELOG.md` — same pattern as WI-01.

---

### WI-03 — `fx-migration-planner` extension (Migration Planner)

**Wraps**: `agents/migration-planner.agent.md`

#### WI-03-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-migration-planner"
  name: ".NET Migration Planner"
  version: "0.1.0"
  description: "Synthesizes assessment findings into a phased, risk-ordered migration plan covering SDK conversion, package updates, multitargeting, and ASP.NET Core migration."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-migration-planner.plan"
      file: "commands/plan.md"
      description: "Synthesize assessment findings into an actionable migration plan. Requires prior assessment output."

tags:
  - "dotnet"
  - "migration"
  - "planning"
```

Note: `user-invocable: false` on the underlying agent means this extension is intended for
orchestrator delegation, not direct manual invocation. Document this limitation in README.

#### WI-03-B `commands/plan.md`

Frontmatter: no `tools` entry (read-only planning agent, no MCP calls).

Body must cover:
- Required inputs: `assessmentContent`, `topologicalProjects`, `dependencyLayers`, `solutionPath`, `targetFramework`.
- Read-only constraint: no code changes, no file edits, no build invocations.
- Skill awareness (conditional):
  - Acknowledge EF6 policy constraints (`ef6-migration-policy`) when EF6 packages appear in the assessment.
  - Acknowledge System.Web adapter guidance (`systemweb-adapters`) when out-of-scope System.Web items are present.
  - Acknowledge Windows Service migration policy (`windows-service-migration`) if Windows Service projects are classified.
- Output: structured migration plan appended to `.fx2dotnet/plan.md`.

#### WI-03-C thru WI-03-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-04 — `fx-sdk-conversion` extension (SDK-Style Project Conversion)

**Wraps**: `agents/sdk-project-conversion.agent.md`

#### WI-04-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-sdk-conversion"
  name: ".NET SDK-Style Project Conversion"
  version: "0.1.0"
  description: "Converts a legacy .NET project file to SDK-style format and iteratively resolves compilation errors until the project builds successfully."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"
  tools:
    - name: "Microsoft.GitHubCopilot.AppModernization.Mcp"
      required: true
    - name: "Swick.Mcp.Fx2dotnet"
      required: true

provides:
  commands:
    - name: "speckit.fx-sdk-conversion.convert"
      file: "commands/convert.md"
      description: "Convert a legacy project file to SDK-style format, then fix build errors."

tags:
  - "dotnet"
  - "sdk"
  - "conversion"
  - "migration"
```

#### WI-04-B `commands/convert.md`

Frontmatter `tools` entries:
```yaml
tools:
  - 'Microsoft.GitHubCopilot.AppModernization.Mcp/convert_project_to_sdk_style'
  - 'Swick.Mcp.Fx2dotnet/GetMinimalPackageSet'
```

Body must cover:
- Argument: `.sln`, `.csproj`, `.vbproj`, or `.fsproj` path.
- State file: `## SDK Conversion` section in `.fx2dotnet/{ProjectName}.md`.
- Post-conversion Build Fix delegation pattern.
- No skill requirements for this phase (pure structural conversion).

#### WI-04-C thru WI-04-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-05 — `fx-package-compat` extension (Package Compatibility Core Migration)

**Wraps**: `agents/package-compat-core.agent.md`

#### WI-05-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-package-compat"
  name: ".NET Package Compatibility Migration"
  version: "0.1.0"
  description: "Applies a pre-built package compatibility plan to a .NET solution. Executes chunked package version updates and invokes Build Fix after each chunk."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-package-compat.migrate"
      file: "commands/migrate.md"
      description: "Apply a pre-built chunked package update plan, running Build Fix after each chunk."

tags:
  - "dotnet"
  - "nuget"
  - "packages"
  - "migration"
```

Note: `user-invocable: false` on the underlying agent — document in README that this is designed
for orchestrator invocation after planning is complete.

#### WI-05-B `commands/migrate.md`

Frontmatter: no `tools` entry (no direct MCP calls in this agent).

Body must cover:
- Required inputs: `solutionPath`, `targetFramework`, chunked update plan from `.fx2dotnet/package-updates.md`.
- Low-confidence item review gate before proceeding.
- Execution state tracking in `.fx2dotnet/package-updates.md`.
- Preferences file `.fx2dotnet/preferences.md` for `alwaysContinue` flag.
- No skill requirements (plan-driven, not error-reactive).

#### WI-05-C thru WI-05-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-06 — `fx-multitarget` extension (Multitarget Migration)

**Wraps**: `agents/multitarget.agent.md`

#### WI-06-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-multitarget"
  name: ".NET Multitarget Migration"
  version: "0.1.0"
  description: "Adds multiple target frameworks to a .NET project. Identifies pre-migration API issues, applies minimal fixes with checkpoints, and verifies with Build Fix."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-multitarget.migrate"
      file: "commands/migrate.md"
      description: "Add modern target framework(s) to a project, apply minimal compatibility fixes, and build-verify."

tags:
  - "dotnet"
  - "multitarget"
  - "migration"
  - "frameworks"
```

#### WI-06-B `commands/migrate.md`

Frontmatter: no `tools` entry (no direct MCP calls).

Body must cover:
- Argument: project path and target frameworks to add (default `net10.0`).
- State file: `## Multitarget` section in `.fx2dotnet/{ProjectName}.md`.
- Skill activation guidance — all conditional on detected error/code patterns:
  - Load `skills/ef6-migration-policy/SKILL.md` when EF or `DbContext`/`ObjectContext` types appear.
  - Load `skills/systemweb-adapters/SKILL.md` when `HttpContext`, `HttpRequest`, or `HttpResponse` compile errors appear.
  - Load `skills/windows-service-migration/SKILL.md` when `ServiceBase` or `ServiceController` types appear.
- Build Fix delegation pattern after TFM update.
- Layer-by-layer checkpoint tracking for the orchestrator.

#### WI-06-C thru WI-06-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-07 — `fx-aspnet-web` extension (ASP.NET Framework to ASP.NET Core Web Migration)

**Wraps**: `agents/aspnet-framework-to-aspnetcore-web-migration.agent.md`

#### WI-07-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-aspnet-web"
  name: "ASP.NET Framework to ASP.NET Core Web Migration"
  version: "0.1.0"
  description: "Migrates an ASP.NET Framework web host to ASP.NET Core by inventorying endpoints, scaffolding a new host, and porting artifacts incrementally."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-aspnet-web.migrate"
      file: "commands/migrate.md"
      description: "Migrate a legacy ASP.NET Framework web host to a new ASP.NET Core project."

tags:
  - "dotnet"
  - "aspnet"
  - "migration"
  - "aspnetcore"
```

Note: `user-invocable: false` on the underlying agent — document in README.

#### WI-07-B `commands/migrate.md`

Frontmatter: no `tools` entry (no direct MCP calls).

Body must cover:
- Argument: legacy web project path, optional solution path and target framework.
- Strategy: endpoint inventory → scaffold new ASP.NET Core host → port artifacts incrementally.
- State file: `## Web Migration` section in `.fx2dotnet/{ProjectName}.md`.
- Skill activation guidance — conditional:
  - Load `skills/systemweb-adapters/SKILL.md` for all System.Web adapter bridging decisions.
  - Load `skills/owin-identity/SKILL.md` when OWIN middleware, `IAppBuilder`, Katana packages, or Identity auth patterns are present.
- Route inventory delegation to `fx-route-inventory` / Legacy Web Route Inventory.
- Build Fix delegation after each porting slice.

#### WI-07-C thru WI-07-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-08 — `fx-build-fix` extension (Build Fix)

**Wraps**: `agents/build-fix.agent.md`

#### WI-08-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-build-fix"
  name: ".NET Build Fix"
  version: "0.1.0"
  description: "Runs a dotnet build/fix loop: builds a .NET project, diagnoses errors, and applies minimal fixes iteratively until the build succeeds."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-build-fix.fix"
      file: "commands/fix.md"
      description: "Run a build/fix loop on a .NET project until it compiles successfully."

tags:
  - "dotnet"
  - "build"
  - "fix"
  - "migration"
```

Note: `user-invocable: false` on the underlying agent — document in README.

#### WI-08-B `commands/fix.md`

Frontmatter: no `tools` entry (no direct MCP calls).

Body must cover:
- Argument: `.sln`, `.csproj`, `.vbproj`, or `.fsproj` path.
- State file: `## Build Fix` section in `.fx2dotnet/{ProjectName}.md` with inline retry counts.
- Minimal-fix discipline: one error group at a time, no speculative changes.
- Skill activation guidance — conditional, error-pattern gated:
  - Load `skills/ef6-migration-policy/SKILL.md` when EF6-related compile errors appear.
  - Load `skills/systemweb-adapters/SKILL.md` when `System.Web` namespace errors appear.
  - Load `skills/windows-service-migration/SKILL.md` when `ServiceBase` / `ServiceController` errors appear.

#### WI-08-C thru WI-08-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-09 — `fx-route-inventory` extension (Legacy Web Route Inventory)

**Wraps**: `agents/legacy-web-route-inventory.agent.md`

#### WI-09-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-route-inventory"
  name: "Legacy ASP.NET Route Inventory"
  version: "0.1.0"
  description: "Extracts a route and endpoint inventory from a legacy ASP.NET web project: controllers, routing config, auth attributes, and request/response contracts."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-route-inventory.scan"
      file: "commands/scan.md"
      description: "Scan a legacy ASP.NET project and produce an endpoint inventory with routes, auth, and contracts."

tags:
  - "dotnet"
  - "aspnet"
  - "routes"
  - "inventory"
```

Note: `user-invocable: false` on the underlying agent — document in README.

#### WI-09-B `commands/scan.md`

Frontmatter: no `tools` entry (read-only, no MCP calls).

Body must cover:
- Argument: legacy web project path or folder.
- Read-only scope: scan controller source files and routing config only.
- Exclusions: `bin/`, `obj/`, `.vs/`, generated files, package content.
- What to extract: route templates, HTTP method constraints, auth attributes, request/response types.
- No skill requirements for this phase.

#### WI-09-C thru WI-09-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-10 — `fx-project-detector` extension (Project Type Detector)

**Wraps**: `agents/project-type-detector.agent.md`

#### WI-10-A `extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx-project-detector"
  name: ".NET Project Type Detector"
  version: "0.1.0"
  description: "Reads a .NET project file and classifies it as a web application host, web library, Windows Service, or other type, and reports whether it uses SDK-style format."
  author: "fx2dotnet"
  repository: "https://github.com/RogerBestMSFT/fx2dotnet"
  license: "MIT"

requires:
  speckit_version: ">=0.1.0"

provides:
  commands:
    - name: "speckit.fx-project-detector.classify"
      file: "commands/classify.md"
      description: "Classify a .NET project file type and SDK-style format status."

tags:
  - "dotnet"
  - "classification"
  - "project"
```

Note: `user-invocable: false` on the underlying agent — document in README.

#### WI-10-B `commands/classify.md`

Frontmatter: no `tools` entry (read-only, no MCP calls).

Body must cover:
- Argument: `.csproj`, `.vbproj`, or `.fsproj` path.
- Classification categories:
  - `web-app-host`: host-level indicators present (`Global.asax`, `Startup.cs` with `IAppBuilder`,
    `WebApiConfig`, `RouteConfig`, `OutputType` set to `Exe` or absent with host artifacts).
  - `web-library`: references web frameworks but `OutputType` is `Library`, no host artifacts.
  - `windows-service`: references `System.ServiceProcess`, `ServiceBase`, or contains `OnStart`/`OnStop`.
  - `other`: class libraries, console apps, worker services not matching above.
- SDK-style detection: `<Project Sdk="...">` vs `<Project ToolsVersion="...">`.
- Ambiguous evidence → return `uncertain` and list evidence.
- No skill requirements for this phase.

#### WI-10-C thru WI-10-E: `README.md`, `LICENSE`, `CHANGELOG.md`.

---

### WI-11 — Cross-Extension Validation Checklist

**File**: `speckit-extensions/VALIDATION-CHECKLIST.md`

Content must include a per-extension verification table covering:

| Check | Description |
|-------|-------------|
| Required files | `extension.yml`, `README.md`, `LICENSE`, and at least one command file are present |
| Schema version | `schema_version: "1.0"` present in `extension.yml` |
| ID pattern | `extension.id` matches `^[a-z0-9-]+$` |
| Version format | `extension.version` matches `X.Y.Z` exactly |
| Command name pattern | All `provides.commands[].name` match `^speckit\.[a-z0-9-]+\.[a-z0-9-]+$` |
| Command file exists | Each `provides.commands[].file` path resolves to an existing file |
| MCP correctness | Extensions that wrap assessment or SDK conversion declare both MCP servers as required; all others omit `requires.tools` |
| Skill guidance present | Extensions wrapping build-fix, multitarget, assessment, and planner agents include conditional skill guidance in command body |
| Non-invasive | Running `git diff --name-only` against baseline shows only new files under `speckit-extensions/` |
| Unique command names | No two extensions share a command name |

Also include a CLI dry-run section if Spec-Kit supports it:
```shell
specify extension validate speckit-extensions/dotnet-fx-migration
specify extension validate speckit-extensions/fx-assessment
# ... one line per extension
```

---

### WI-12 — Catalog Fragment (Optional)

**File**: `speckit-extensions/catalog-fragment.json`

Provides a ready-to-merge fragment for the Spec-Kit community catalog. Not a change to any upstream
catalog file.

Schema mirrors `extensions/catalog.json` in the Spec-Kit repo:
```json
{
  "schema_version": "1.0",
  "extensions": {
    "dotnet-fx-migration":    { ... },
    "fx-assessment":          { ... },
    "fx-migration-planner":   { ... },
    "fx-sdk-conversion":      { ... },
    "fx-package-compat":      { ... },
    "fx-multitarget":         { ... },
    "fx-aspnet-web":          { ... },
    "fx-build-fix":           { ... },
    "fx-route-inventory":     { ... },
    "fx-project-detector":    { ... }
  }
}
```

Each entry needs: `name`, `id`, `version`, `description`, `author`, `repository`,
`download_url` (placeholder: `"TBD"`), and `tags`.

---

## Execution Order and Dependencies

```
WI-01 thru WI-10  ← all independent, can be executed in parallel per-extension
        │
        ▼
      WI-11 (VALIDATION-CHECKLIST.md) ← requires all extensions to exist
        │
        ▼
      WI-12 (catalog-fragment.json)  ← optional, after WI-11
```

Each work item within an extension (e.g., WI-02-A through WI-02-E) is independent of other
extensions but should be created together in one pass.

---

## Verification Gates

Before closing each work item:

1. **No existing file modified**: confirm `git status` shows only additions under `speckit-extensions/`.
2. **Manifest validity**: `extension.yml` parses as valid YAML and contains `schema_version`, `extension`, `requires`, and `provides.commands`.
3. **Command name conformance**: value matches `speckit.{extension.id}.{command}` exactly.
4. **MCP dependency accuracy**:
   - WI-02 (`fx-assessment`) and WI-04 (`fx-sdk-conversion`): both MCP servers declared as `required: true`.
   - WI-01, WI-03, WI-05, WI-06, WI-07, WI-08, WI-09, WI-10: no `requires.tools` block.
5. **Skill guidance scope**: only present in command files for WI-02, WI-03, WI-06, WI-07, WI-08;
   absent from WI-04, WI-05, WI-09, WI-10.
6. **User-invocable note**: WI-03, WI-05, WI-07, WI-08, WI-09, WI-10 READMEs explicitly state
   the extension is designed for orchestrator delegation, not direct manual use.

---

## Publishing Setup

Publishing turns the local extension files into installable, discoverable packages in the Spec-Kit
catalog. There are two tiers: **installable release** (anyone can `specify extension add --from <url>`)
and **catalog-listed** (discoverable via `specify extension search`). The steps below cover both.

All publishing work is additive — no existing repo files change.

---

### PUB-01 — Repository and release structure

Each extension lives in its own sub-folder under `speckit-extensions/` within this repo.
Releases are GitHub Releases tagged per-extension so download URLs are stable and independent.

**Tag convention** — one tag per extension per version:

```
{extension-id}-v{version}
```

Examples:
```
dotnet-fx-migration-v0.1.0
fx-assessment-v0.1.0
fx-sdk-conversion-v0.1.0
```

**Release archive** — GitHub automatically creates a `.zip` from the tagged tree. The download URL
pattern is:

```
https://github.com/RogerBestMSFT/fx2dotnet/archive/refs/tags/{extension-id}-v{version}.zip
```

For the initial release of all ten extensions at `0.1.0`, ten separate tags must be created. This
keeps per-extension version histories independent so a fix to `fx-build-fix` does not force a
version bump on `fx-assessment`.

**Work items**:

| ID | Action |
|----|--------|
| PUB-01-A | Confirm the `RogerBestMSFT/fx2dotnet` repository is public on GitHub (required for catalog download URLs to resolve). |
| PUB-01-B | Ensure each `extension.yml` `repository` field is set to `https://github.com/RogerBestMSFT/fx2dotnet` (already reflected in WI-01 thru WI-10 manifests). |
| PUB-01-C | Update WI-12 `catalog-fragment.json` to replace `"TBD"` download URLs with the real archive URL pattern for each extension once tags are known. |

---

### PUB-02 — Add `.gitignore` to each extension folder

The Spec-Kit publishing guide recommends a `.gitignore` per extension. Create one in each of the
ten extension subdirectories under `speckit-extensions/`. Minimum content:

```gitignore
# User-local config overrides (never commit)
*-config.local.yml

# OS artifacts
.DS_Store
Thumbs.db
```

This file does not affect the extension's runtime behavior but is required for the publishing
checklist.

---

### PUB-03 — Local validation before tagging

Run the following before creating any release tag:

```shell
# Validate each extension manifest
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

# Test a local dev install for at least one extension end-to-end
specify extension add --dev speckit-extensions/dotnet-fx-migration
specify extension add --dev speckit-extensions/fx-assessment
```

All validations must pass before proceeding to tagging.

---

### PUB-04 — Create GitHub Releases (one per extension)

After validation passes, create one tagged release per extension. The recommended approach is to
batch all ten for the initial `0.1.0` release.

**Steps**:

1. Commit all `speckit-extensions/` files on `main`:
   ```shell
   git add speckit-extensions/
   git commit -m "feat: add spec-kit extensions for all migration agents (0.1.0)"
   ```

2. Create one lightweight tag per extension:
   ```shell
   git tag dotnet-fx-migration-v0.1.0
   git tag fx-assessment-v0.1.0
   git tag fx-migration-planner-v0.1.0
   git tag fx-sdk-conversion-v0.1.0
   git tag fx-package-compat-v0.1.0
   git tag fx-multitarget-v0.1.0
   git tag fx-aspnet-web-v0.1.0
   git tag fx-build-fix-v0.1.0
   git tag fx-route-inventory-v0.1.0
   git tag fx-project-detector-v0.1.0
   git push origin --tags
   ```

3. On GitHub, create a Release for each tag:
   - Title: `{Extension Name} v0.1.0`
   - Body: copy the initial `CHANGELOG.md` entry for that extension
   - No additional assets needed — the auto-generated source archive is the download URL

4. Confirm each generated archive URL resolves:
   ```
   https://github.com/RogerBestMSFT/fx2dotnet/archive/refs/tags/dotnet-fx-migration-v0.1.0.zip
   ```

5. Update `speckit-extensions/catalog-fragment.json` (WI-12) with the confirmed URLs and commit.

---

### PUB-05 — Test installation from release URL

Before submitting to the community catalog, verify that install-from-URL works:

```shell
specify extension add dotnet-fx-migration --from \
  https://github.com/RogerBestMSFT/fx2dotnet/archive/refs/tags/dotnet-fx-migration-v0.1.0.zip

specify extension add fx-assessment --from \
  https://github.com/RogerBestMSFT/fx2dotnet/archive/refs/tags/fx-assessment-v0.1.0.zip
```

Repeat for each extension. Confirm the install completes, the command is registered, and a
`specify extension list` shows the installed extension at the expected version.

---

### PUB-06 — Submit to the Spec-Kit community catalog

The community catalog lives in the `github/spec-kit` repository in
`extensions/catalog.community.json`. Submission is via pull request.

**Steps**:

1. Fork `https://github.com/github/spec-kit` on GitHub.

2. Clone the fork locally:
   ```shell
   git clone https://github.com/RogerBestMSFT/spec-kit.git
   cd spec-kit
   git checkout -b add-fx2dotnet-extensions
   ```

3. Edit `extensions/catalog.community.json`.
   Add one entry per extension under the top-level `"extensions"` object, in alphabetical order
   by key. Each entry must follow this schema exactly (sourced from the Spec-Kit publishing guide):

   ```json
   "dotnet-fx-migration": {
     "name": ".NET Framework to Modern .NET Migration",
     "id": "dotnet-fx-migration",
     "description": "Orchestrates end-to-end .NET Framework to modern .NET migration via a 7-phase workflow.",
     "author": "fx2dotnet",
     "version": "0.1.0",
     "download_url": "https://github.com/RogerBestMSFT/fx2dotnet/archive/refs/tags/dotnet-fx-migration-v0.1.0.zip",
     "repository": "https://github.com/RogerBestMSFT/fx2dotnet",
     "homepage": "https://github.com/RogerBestMSFT/fx2dotnet",
     "documentation": "https://github.com/RogerBestMSFT/fx2dotnet/blob/main/speckit-extensions/dotnet-fx-migration/README.md",
     "changelog": "https://github.com/RogerBestMSFT/fx2dotnet/blob/main/speckit-extensions/dotnet-fx-migration/CHANGELOG.md",
     "license": "MIT",
     "requires": {
       "speckit_version": ">=0.1.0"
     },
     "provides": {
       "commands": 1,
       "hooks": 0
     },
     "tags": ["dotnet", "migration", "modernization", "aspnet"],
     "verified": false,
     "downloads": 0,
     "stars": 0,
     "created_at": "2026-04-01T00:00:00Z",
     "updated_at": "2026-04-01T00:00:00Z"
   }
   ```

   Repeat for all ten extensions. For extensions that require MCP tools (`fx-assessment`,
   `fx-sdk-conversion`), add a `requires.tools` array:
   ```json
   "requires": {
     "speckit_version": ">=0.1.0",
     "tools": [
       { "name": "Microsoft.GitHubCopilot.AppModernization.Mcp", "required": true },
       { "name": "Swick.Mcp.Fx2dotnet", "required": true }
     ]
   }
   ```

   Update the top-level `"updated_at"` field to the current date.

4. Update the Community Extensions table in the `spec-kit` root `README.md`. Add one row per
   extension, in alphabetical order. Use category `process` for the orchestrator and
   `code` for the individual migration and fix agents:

   | Extension Name | Description | Category | Effect | Repo |
   |---|---|---|---|---|
   | .NET Framework to Modern .NET Migration | Orchestrates 7-phase .NET Framework modernization | `process` | Read+Write | [fx2dotnet](https://github.com/RogerBestMSFT/fx2dotnet) |
   | .NET Solution Assessment | Assesses solution for migration readiness | `code` | Read-only | [fx2dotnet](https://github.com/RogerBestMSFT/fx2dotnet) |
   | … (one row per extension) | | | | |

5. Commit and push:
   ```shell
   git add extensions/catalog.community.json README.md
   git commit -m "Add fx2dotnet migration extensions to community catalog

   - 10 extensions for .NET Framework → modern .NET migration
   - IDs: dotnet-fx-migration, fx-assessment, fx-migration-planner,
     fx-sdk-conversion, fx-package-compat, fx-multitarget, fx-aspnet-web,
     fx-build-fix, fx-route-inventory, fx-project-detector
   - Version: 0.1.0
   - Author: fx2dotnet
   "
   git push origin add-fx2dotnet-extensions
   ```

6. Open a pull request on `github/spec-kit` using this body template:

   ```markdown
   ## Extension Submission

   **Count**: 10 extensions (single batch for the fx2dotnet plugin)
   **Repository**: https://github.com/RogerBestMSFT/fx2dotnet
   **Version**: 0.1.0

   ### Extensions submitted
   | ID | Description |
   |----|-------------|
   | dotnet-fx-migration | End-to-end orchestrator |
   | fx-assessment | Solution assessment |
   | fx-migration-planner | Migration planning |
   | fx-sdk-conversion | SDK-style project conversion |
   | fx-package-compat | Package compatibility migration |
   | fx-multitarget | Multitarget framework migration |
   | fx-aspnet-web | ASP.NET Framework to Core web migration |
   | fx-build-fix | Build error fix loop |
   | fx-route-inventory | Legacy route and endpoint inventory |
   | fx-project-detector | Project type classification |

   ### Checklist
   - [x] Valid extension.yml manifests (all 10 pass `specify extension validate`)
   - [x] README.md, LICENSE, CHANGELOG.md present in each extension folder
   - [x] GitHub releases created with matching tags
   - [x] Download URLs tested and resolve correctly
   - [x] All commands tested via `specify extension add --from <url>`
   - [x] No security vulnerabilities
   - [x] Added all 10 entries to catalog.community.json
   - [x] Added all 10 rows to Community Extensions table in README.md
   ```

---

### PUB-07 — Release automation (optional, recommended for future versions)

**All ten extensions can be published simultaneously** using a GitHub Actions matrix strategy.
A single `workflow_dispatch` run with one `version` input fans out to 10 parallel jobs — one per
extension — each independently validating, tagging, and creating its own GitHub Release.

This replaces the manual `git tag` / GitHub UI approach in PUB-04 for all future version bumps.
For the very first `0.1.0` release it can also be used by triggering it on `main` after the initial
commit of all extension files.

Create `.github/workflows/release-extensions.yml` (new file; does not touch any existing files):

```yaml
name: Release All Spec-Kit Extensions

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release for all extensions (e.g. 0.1.0)'
        required: true

jobs:
  release:
    name: Release ${{ matrix.extension }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false          # a failure in one extension does not cancel the others
      matrix:
        extension:
          - dotnet-fx-migration
          - fx-assessment
          - fx-migration-planner
          - fx-sdk-conversion
          - fx-package-compat
          - fx-multitarget
          - fx-aspnet-web
          - fx-build-fix
          - fx-route-inventory
          - fx-project-detector

    steps:
      - uses: actions/checkout@v4

      - name: Install spec-kit CLI
        run: pip install spec-kit

      - name: Validate manifest
        run: specify extension validate speckit-extensions/${{ matrix.extension }}

      - name: Create tag
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag ${{ matrix.extension }}-v${{ inputs.version }}
          git push origin ${{ matrix.extension }}-v${{ inputs.version }}

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ matrix.extension }}-v${{ inputs.version }}
          name: "${{ matrix.extension }} v${{ inputs.version }}"
          body_path: speckit-extensions/${{ matrix.extension }}/CHANGELOG.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**How it works**:

- `strategy.matrix` lists all ten extension IDs. GitHub Actions spawns one runner per entry
  and runs them in parallel within the same workflow run.
- `fail-fast: false` means if one extension's validation fails, the other nine continue —
  failures are isolated per extension rather than aborting the batch.
- Each job creates its own tag (`{extension-id}-v{version}`) and GitHub Release independently,
  keeping per-extension version histories decoupled.
- The single `version` input applies uniformly across all extensions in that run. For selective
  single-extension releases (e.g. a patch to `fx-build-fix` only), see the single-extension
  variant below.

**Single-extension variant** — add a second workflow for targeted releases:

```yaml
name: Release Single Spec-Kit Extension

on:
  workflow_dispatch:
    inputs:
      extension_id:
        description: 'Extension folder name (e.g. fx-build-fix)'
        required: true
      version:
        description: 'Version to release (e.g. 0.1.1)'
        required: true

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install spec-kit
      - run: specify extension validate speckit-extensions/${{ inputs.extension_id }}
      - run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag ${{ inputs.extension_id }}-v${{ inputs.version }}
          git push origin ${{ inputs.extension_id }}-v${{ inputs.version }}
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ inputs.extension_id }}-v${{ inputs.version }}
          name: "${{ inputs.extension_id }} v${{ inputs.version }}"
          body_path: speckit-extensions/${{ inputs.extension_id }}/CHANGELOG.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Store this as `.github/workflows/release-extension-single.yml`.

**Summary of what "publish all at once" looks like end-to-end**:

1. All extension files committed to `main` (WI-01–10 + PUB-02 done).
2. Trigger `Release All Spec-Kit Extensions` workflow, input `version: 0.1.0`.
3. 10 parallel jobs run: validate → tag → GitHub Release. Total elapsed time ≈ time for one job.
4. Confirm all 10 releases appear on the GitHub Releases page.
5. Update `speckit-extensions/catalog-fragment.json` with the now-known download URLs (WI-12).
6. Submit catalog PR (PUB-06) — single PR covers all 10.

---

### DECISION — MCP server deployment strategy

Two extensions (`fx-assessment`, `fx-sdk-conversion`) declare `Swick.Mcp.Fx2dotnet` as a required
MCP dependency. Before PUB-01, decide how that server is resolved at runtime.

| Option | How it works | When to use |
|--------|-------------|-------------|
| **A — NuGet.org (current default)** | `dnx` downloads the package from `https://api.nuget.org/v3/index.json` on first use. The existing `.mcp.json` already configures this. No additional setup steps. | Stable, published builds; any machine with internet access. |
| **B — Local build + workspace `.mcp.json` override** | Run `dotnet pack fx2dotnet.slnx -c Release --output local-feed/` to produce a local `.nupkg`. Write a `.mcp.json` into the user's solution workspace pointing `dnx --source` at that folder. VS Code picks up the workspace `.mcp.json` alongside the plugin-level one. | Local dev / pre-publish testing. Not committed to the plugin repo. |
| **C — Machine-wide local NuGet feed** | Run `dotnet nuget add source local-feed/ --name fx2dotnet-local` once. The existing `dnx` invocation resolves the package from the local feed automatically on every machine where the source is registered. | Sharing a local build with a team without touching workspace files. |

**Impact on extension work items** (only if Option B or C is chosen):

- `fx-assessment` and `fx-sdk-conversion` each gain a second command and a bundled script:

  ```
  fx-assessment/
  ├── commands/
  │   ├── run.md           ← existing (WI-02-B)
  │   └── setup.md         ← new: builds MCP server, configures local source
  └── scripts/
      └── setup.ps1        ← PowerShell: dotnet pack + dnx source config / .mcp.json write
  ```

- `extension.yml` `provides.commands` for each extension gains one entry:
  ```yaml
  - name: "speckit.fx-assessment.setup"
    file: "commands/setup.md"
    description: "Build and configure the Swick.Mcp.Fx2dotnet MCP server from local source."
  ```

- `setup.md` frontmatter references the script via `scripts.ps: scripts/setup.ps1`.

- These are additive only — `run.md` and the rest of each extension are unchanged.

**Recommendation**: Start with Option A. Add Option B/C setup commands only if the NuGet-published
package is not yet available or a local iteration loop is needed.

**Action required**: Confirm Option A, B, or C before executing PUB-01.

---

### Publishing Work Item Summary

| ID | Description | Depends on | Optional |
|----|-------------|-----------|----------|
| PUB-01 | Repo structure confirmation and download URL pattern | Decision above + WI-01–10 complete | No |
| PUB-02 | Add `.gitignore` to each extension folder | WI-01–10 complete | No |
| PUB-03 | Local `specify extension validate` and dev-install test | PUB-01, PUB-02 | No |
| PUB-04 | Create GitHub release tags and GitHub Releases | PUB-03 passes | No |
| PUB-05 | Test install-from-URL for each extension | PUB-04 complete | No |
| PUB-06 | Submit PR to `github/spec-kit` community catalog | PUB-05 passes | Yes (community visibility) |
| PUB-07 | GitHub Actions workflow for future releases | PUB-04 complete | Yes (automation) |

```
WI-01–10 done → WI-11 validation → WI-12 catalog fragment
                         │
                         ▼
              PUB-01 + PUB-02 (parallel)
                         │
                         ▼
                      PUB-03
                         │
                         ▼
                      PUB-04
                         │
                         ▼
                      PUB-05
                        / \
                  PUB-06   PUB-07
               (catalog PR) (CI workflow)
```
