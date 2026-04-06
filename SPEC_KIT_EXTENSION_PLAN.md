# Spec-Kit fx2dotnet Extension Suite Plan

**Document Version**: 1.0  
**Date**: April 3, 2026  
**Status**: For Review  

> **Execution backlog**: [SPEC_KIT_EXTENSION_WORK_ITEMS.md](SPEC_KIT_EXTENSION_WORK_ITEMS.md) tracks the concrete work items derived from this plan and the companion implementation details.

---

## Executive Summary

This plan describes the architecture, implementation phases, and verification strategy for converting the fx2dotnet project into a fully isolated, installable Spec-Kit extension suite. The extension package will replicate all current fx2dotnet migration capabilities without modifying any spec-kit core files or folders, using a per-agent package model with shared support infrastructure, bundled runtime artifacts, and GitHub release-based distribution via spec-kit's native catalog system.

**Key Decision Points Locked**:
- **Packaging**: Per-agent extensions (1 extension per migration phase/agent) + 1 shared support customization extension
- **Distribution**: GitHub release ZIP artifacts referenced by internal install-allowed catalog
- **Artifacts**: Bundled binaries/runtime payloads inside each extension ZIP (not runtime dnx/NuGet pull)
- **Catalog**: Internal install-allowed catalog as primary + optional public discovery listing

---

## Part 1: Current State

### Source Codebases

| Codebase | Location | Role |
|----------|----------|------|
| **fx2dotnet** | C:\RogerBestMSFT\fx2dotnet | Source of truth for orchestration, agents, skills, and MCP server |
| **spec-kit** | C:\spec-kit-main\spec-kit-main | Extension system framework, CLI, and manifest contracts |

### Current fx2dotnet Architecture

```
fx2dotnet/
├── agents/                              # 10 orchestration/phase files
│   ├── dotnet-fx-to-modern-dotnet.md   # Orchestrator (7-phase workflow)
│   ├── assessment.agent.md              # Phase 1: Discovery
│   ├── migration-planner.agent.md       # Phase 2: Planning
│   ├── sdk-project-conversion.agent.md  # Phase 3: SDK normalization
│   ├── package-compat-core.agent.md     # Phase 4: Package updates
│   ├── multitarget.agent.md             # Phase 5: Multitarget additions
│   ├── aspnet-framework-to-aspnetcore-web-migration.agent.md  # Phase 6: Web migration
│   ├── build-fix.agent.md               # Cross-phase: Error remediation
│   ├── project-type-detector.agent.md   # Support: Project classification
│   └── legacy-web-route-inventory.agent.md  # Support: Route extraction
│
├── skills/                              # Domain knowledge policies
│   ├── ef6-migration-policy/SKILL.md
│   ├── systemweb-adapters/SKILL.md + references/
│   ├── windows-service-migration/SKILL.md
│   ├── owin-identity/SKILL.md
│   └── [4 empty placeholders]
│
├── src/fx2dotnet/                       # MCP server source
│   ├── fx2dotnet.csproj
│   ├── Program.cs
│   ├── Tools.cs                         # MCP tool definitions
│   ├── Models/
│   ├── Services/
│   └── .mcp/server.json
│
├── .mcp.json                            # MCP server bootstrap (2 servers)
├── plugin.json                          # Plugin metadata
├── plugin-instructions.md               # Workspace instructions (attachment)
└── README.md                            # User-facing guide
```

### Spec-Kit Extension System Overview

**Installation Flow**:
```
User runs: specify extension add fx2dotnet-assessment
    ↓
CLI searches catalog (install_allowed: true)
    ↓
Downloads ZIP from catalog.download_url
    ↓
Extracts to .specify/extensions/fx2dotnet-assessment/
    ↓
Registers manifest + commands in .registry
    ↓
Transpiles command .md files to .claude/commands/, .copilot/commands/, etc.
    ↓
Registers hooks in .specify/extensions.yml
    ↓
Returns success (config templates can now be edited)
```

**Key Constraints**:
- No modifications to spec-kit core templates, scripts, or source
- Extensions are additive only; extensions cannot shadow core commands
- Configuration lives in extension-local folders (never in core)
- Every extension must include extension.yml manifest
- Command files are universal Markdown format; CLI transpiles to agent-specific formats
- Hooks run at project level via chain-of-responsibility (after_tasks, after_implement)

---

## Part 2: Target Architecture

### Extension Topology (Per-Agent Model)

The fx2dotnet workflow will be split into **11 extension packages**:

#### Primary Extensions (1 per phase)

| Extension ID | Agent/Phase | Purpose | Depends On | MCP Tools |
|------------|------------|---------|-----------|-----------|
| `fx2dotnet-orchestrator` | Orchestrator | Drives 7-phase sequential workflow | fs-read/write, agent-invoke, todo-management | N/A |
| `fx2dotnet-assessment` | Assessment | Discover frameworks, classify projects, compute layers | project-type-detector | Microsoft.GitHubCopilot.AppModernization.Mcp, Swick.Mcp.Fx2dotnet |
| `fx2dotnet-planner` | Migration Planner | Synthesize assessment into chunked execution plan | assessment | N/A |
| `fx2dotnet-sdk-conversion` | SDK Conversion | Normalize projects to SDK-style | assessment, build-fix, AppModernization.Mcp | Microsoft.GitHubCopilot.AppModernization.Mcp, Swick.Mcp.Fx2dotnet |
| `fx2dotnet-package-compat` | Package Compatibility | Apply chunked package updates | assessment, planner | Swick.Mcp.Fx2dotnet |
| `fx2dotnet-multitarget` | Multitarget | Add target frameworks layer-by-layer | sdk-conversion, build-fix | N/A |
| `fx2dotnet-web-migration` | ASP.NET Web Migration | Create side-by-side ASP.NET Core host + port handlers | assessment, multitarget | N/A |
| `fx2dotnet-build-fix` | Build Fix | Iterative build → diagnose → fix loop | N/A (cross-phase, invoked by others) | N/A |

#### Support Extensions

| Extension ID | Capability | Purpose | Shared By |
|------------|-----------|---------|-----------|
| `fx2dotnet-support-core` | Shared utilities | State contract docs, common command fragments, config helpers | All primary extensions |
| `fx2dotnet-project-classifier` | Type detection | Determine SDK-style status, project types (web-host, library, service) | Assessment, Planning |
| `fx2dotnet-web-route-inventory` | Web analysis | Discover routes in legacy web applications | Web Migration |

### Individual Extension Behavior (Detailed)

This section explains how each extension behaves at runtime, what it reads/writes, and how it participates in the end-to-end modernization workflow.

#### 1) fx2dotnet-support-core

- Role: Shared foundation extension that defines common contracts and utilities used by all other extensions.
- Typical commands: contract validation, shared path resolution, MCP invocation wrappers, standardized logging helpers.
- Inputs: solution path, target framework, extension-local config.
- Outputs: normalized helper outputs consumed by phase extensions; no direct migration-phase ownership.
- Failure policy: fail-fast for contract violations (missing required state sections, invalid phase transition tokens).

#### 2) fx2dotnet-project-classifier

- Role: Project typing utility extension used by assessment/planning to classify project type and conversion eligibility.
- Typical commands: classify project as web host, library, console, service; detect SDK-style status.
- Inputs: project files (`.csproj`), solution graph metadata, optional assessment config.
- Outputs: classification records referenced by assessment report and migration plan.
- Failure policy: if uncertain classification, emit explicit `needs-user-confirmation` marker instead of guessing.

#### 3) fx2dotnet-assessment

- Role: Phase 1 discovery engine for solution-wide inventory and compatibility posture.
- Typical commands: run assessment, compute dependency layers, collect package baseline.
- Inputs: solution file, project graph, NuGet/package metadata, classifier outputs, MCP tool responses.
- Outputs:
  - `.fx2dotnet/analysis.md`
  - `.fx2dotnet/package-updates.md` (initial findings)
- Dependency position: first phase command in orchestrator flow after initialization.
- Failure policy: hard stop if dependency layers or classifications cannot be produced.

#### 4) fx2dotnet-planner

- Role: Phase 2 plan synthesis from assessment findings into executable migration order.
- Typical commands: generate ordered migration plan and chunked package update strategy.
- Inputs: `.fx2dotnet/analysis.md`, `.fx2dotnet/package-updates.md`, target framework.
- Outputs: appended/updated plan content in `.fx2dotnet/plan.md`.
- Dependency position: must run after assessment and before any code-changing phase.
- Failure policy: if unresolved ambiguities remain, produce explicit open-questions block and stop for user input.

#### 5) fx2dotnet-build-fix

- Role: Cross-phase remediation utility for compile/restore/test failures.
- Typical commands: run build diagnostics, classify error type, apply minimal fix pattern, revalidate.
- Inputs: active project path, recent build output, phase context.
- Outputs: project-specific fix notes in `.fx2dotnet/{ProjectName}.md` under `## Build Fix`.
- Dependency position: invoked by sdk-conversion, package-compat, multitarget, and web-migration as needed.
- Failure policy: bounded retry loop, then escalation with explicit blocker summary.

#### 6) fx2dotnet-sdk-conversion

- Role: Phase 3 normalization of eligible projects to SDK-style format.
- Typical commands: convert project format, prune obsolete metadata, validate post-conversion build.
- Inputs: plan project queue, classification results, conversion MCP operations, build-fix helper.
- Outputs: per-project `## SDK Conversion` state in `.fx2dotnet/{ProjectName}.md`.
- Dependency position: runs layer-by-layer for projects marked `needs-sdk-conversion`.
- Failure policy: stop per project on conversion failure; do not continue to next dependency layer automatically.

#### 7) fx2dotnet-package-compat

- Role: Phase 4 package update execution based on compatibility and risk chunking.
- Typical commands: apply package chunk, restore/build, record status, continue/hold.
- Inputs: `.fx2dotnet/package-updates.md` chunk plan, package compatibility MCP results, build-fix helper.
- Outputs: updated `.fx2dotnet/package-updates.md` execution ledger.
- Dependency position: executes only after SDK normalization completes for targeted projects.
- Failure policy: stop on unresolved package conflicts and request approval for risky substitutions.

#### 8) fx2dotnet-multitarget

- Role: Phase 5 incremental multitargeting from .NET Framework toward modern target frameworks.
- Typical commands: add target frameworks, resolve API compatibility deltas, validate layer sequencing.
- Inputs: migration plan, converted project files, target framework settings, build-fix helper.
- Outputs: per-project `## Multitarget` sections in `.fx2dotnet/{ProjectName}.md`.
- Dependency position: runs after package compatibility stabilization.
- Failure policy: pause on unresolved API gaps; require user decision for behavioral/compatibility trade-offs.

#### 9) fx2dotnet-web-route-inventory

- Role: Support extension for extracting legacy route/handler/module behavior from ASP.NET Framework web hosts.
- Typical commands: inventory routes, identify modules/handlers, map migration candidates.
- Inputs: web project source, configuration files, optional systemweb reference docs.
- Outputs: route inventory artifacts consumed by web-migration commands.
- Dependency position: invoked before or during web-migration planning for web hosts.
- Failure policy: if partial extraction, continue with explicit confidence annotations.

#### 10) fx2dotnet-web-migration

- Role: Phase 6 web-host modernization from ASP.NET Framework host to ASP.NET Core host pattern.
- Typical commands: scaffold new host, port routes incrementally, apply adapter-based compatibility strategy.
- Inputs: plan web-host candidate, route inventory output, multitarget/project state, policy constraints.
- Outputs: per-project `## Web Migration` section in `.fx2dotnet/{ProjectName}.md` and generated host migration notes.
- Dependency position: final major migration phase after multitarget completion.
- Failure policy: stop on host boot/runtime blockers; keep side-by-side migration artifacts for manual validation.

#### 11) fx2dotnet-orchestrator

- Role: Control-plane extension that sequences all phases, enforces order, and manages resume behavior.
- Typical commands: start/resume workflow, phase gating, progress updates, checkpoint writes.
- Inputs: solution path, target framework, existing `.fx2dotnet/plan.md` state.
- Outputs: authoritative progress tracking in `.fx2dotnet/plan.md` and phase invocation history.
- Dependency position: entrypoint and lifecycle coordinator.
- Failure policy: no silent continuation on phase failures; always surface blocked state and next action choices.

### Cross-Extension Execution Contract

1. Each extension owns specific state sections and must not overwrite another extension's ownership scope.
2. Extensions communicate through declared state artifacts (`.fx2dotnet/*.md`) and explicit command invocations.
3. Orchestrator enforces phase gates; support extensions never bypass gate conditions.
4. Build-fix can be invoked by multiple phases but writes to project-scoped build-fix sections only.
5. Any extension emitting low-confidence outputs must include machine-readable uncertainty markers to trigger user confirmation.

> Command templates, config examples, validation scripts, continuity procedures, and the per-extension operational matrix are in [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md), especially [Per-Extension Implementation Map](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#per-extension-implementation-map).

### Multi-Project Execution Contract

To support solutions with many projects (including same-name projects in different folders), the workflow uses explicit project identity and phase status semantics.

1. **Canonical project identity**:
  - `projectId` = normalized relative path from solution root to `.csproj` (for example: `src/Web/Web.csproj`).
  - Display name can remain friendly (`Web`), but all orchestration/state joins must use `projectId`.
2. **Deterministic ordering**:
  - Assessment computes dependency layers and an ordered project list per layer.
  - For each phase, orchestrator processes projects in stable order: layer index ascending, then `projectId` lexical ascending.
3. **Fan-out/fan-in phase behavior**:
  - Fan-out: run phase operation per eligible project in current layer.
  - Fan-in: do not advance to next layer until current layer projects are either `completed`, `blocked`, or explicitly `skipped` with rationale.
4. **Per-project phase ledger**:
  - `plan.md` contains a status matrix keyed by `projectId` and phase (`not-started|in-progress|completed|blocked|skipped`).
  - Resume logic reads this matrix to continue from the exact project + phase checkpoint.
5. **Collision-safe project state files**:
  - If two projects share the same file stem (for example `Web.csproj` in multiple folders), file outputs must avoid collision by suffixing short hash from `projectId`.
  - State content always includes both display name and canonical `projectId`.
6. **Cross-file consistency checks**:
  - `analysis.md`, `plan.md`, `package-updates.md`, and `.fx2dotnet/{ProjectName}.md` sections must reference the same `projectId` set.
  - Missing or extra project entries are phase-gate violations.

### Invariants and Boundaries

**Hard Boundaries** (Non-negotiable):
1. **No spec-kit core file writes**: All commands, config, scripts, assets live under `.specify/extensions/{extension-id}`
2. **No command shadowing**: Commands follow `speckit.{extension-id}.{command}` pattern; no conflicts allowed
3. **Sealed state contract**: `.fx2dotnet/*.md` state files remain unchanged in semantics; extensions produce them via commands
4. **Isolated installation**: Each extension ZIP is self-contained; no interdependency on shared build artifacts
5. **Version independence**: Each extension is versioned independently (SemVer); no "release all together" requirement

**Design Patterns**:
1. **State-driven orchestration**: Orchestrator extension reads/updates `.fx2dotnet/plan.md` and delegates to phase extensions via command invocations
2. **Hook-free phases**: Avoid hooks between phase extensions; use explicit orchestrator sequencing instead (more deterministic)
3. **Bundled artifacts strategy**: Each extension ZIP contains all MCP binaries/runtimes it needs; no post-install fetch
4. **Config inheritance**: Extension defaults → project → local → environment; each extension manages its own config stack
5. **Skill registration**: Extension commands auto-register as agent skills when `--ai-skills` or native skill agents enable it

---

## Part 3: Implementation Phases

### Phase 0: Architecture Lock & Contract Definition *(Prerequisite)*

**Deliverables**:
- Finalized extension ID list and command surface (e.g., `speckit.fx2dotnet-assessment.run`, `speckit.fx2dotnet-build-fix.retry`)
- Documented requires/provides contract for each extension
- State-file interaction semantics (which `.fx2dotnet/*.md` sections each extension reads/writes)
- Canonical project identity schema (`projectId` format, ordering rules, collision-handling rules)
- MCP tool binding strategy (how each extension invokes Microsoft and Swick tools)
- Shared utility/constant definitions for support-core extension

**Outputs**:
- Extension matrix table (locked)
- Command naming reference (locked)
- State contract specification (locked)
- Multi-project execution contract (locked)
- MCP binding diagram (locked)

**Duration**: 1 sprint  
**Dependencies**: None  
**Blockers to Resolve**:
- Confirm orchestrator vs. decentralized phase triggering model (recommendation: 1 orchestrator extension)
- Finalize which skills/policies become shared vs. per-extension

---

### Phase 1: Agent/Capability Decomposition *(Can parallelize per-agent)*

**For each of 10–11 extensions, produce**:
1. **extension.yml manifest** — metadata, requires/provides, hooks, config schema, defaults, defaults
2. **Command Markdown files** — 1–3 commands per extension, each with documented tool/script frontmatter
3. **Config templates** — default YAML for user setup
4. **Embedded documentation** — policy overviews inline or linked from commands
5. **Support asset mapping** — identify reusable vs. unique assets

**Per-Agent Effort** (each agent):
- Read corresponding source agent file from C:\RogerBestMSFT\fx2dotnet\agents\
- Extract narrative workflow, tool invocations, and state-file operations
- Convert to extension command(s) that invoke same workflow via Copilot APIs (read, edit, agent, search, todo)
- Wrap any domain policy (skills) as embedded commands or linked docs
- Define config for user customization (MCP timeouts, retry counts, log levels, etc.)

**Parallelization**: All agent extensions can be authored in parallel after Phase 0 lock.

**Deliverables per extension**:
- `extension.yml`
- `commands/*.md` (1–N command files)
- `{ext-id}-config.template.yml`
- `docs/` folder with policy references or implementation notes
- Manifest validation report

**Duration**: 2–3 sprints (1–2 weeks per pair of extensions working in parallel)  
**Dependencies**: Phase 0  

---

### Phase 2: Shared Support Extension *(Dependent on Phase 1 shape)*

**fx2dotnet-support-core** extension providing:
1. **State contract definitions** — Markdown specs for `.fx2dotnet/plan.md`, `analysis.md`, `package-updates.md`, per-project state sections
2. **Reusable command fragments** — Bash/PowerShell helper scripts for common ops (file reads, config parsing, result formatting)
3. **Shared configuration schemas** — Codified validation expectations for all extension configs
4. **MCP bootstrap helpers** — Scripts/functions to invoke Microsoft and Swick MCP tools with error handling
5. **Dependency graph utilities** — Pre-computed layer-by-layer project ordering logic

**Deliverables**:
- `extension.yml` (requires: speckit_version; provides: commands for each shared routine + config helpers)
- `commands/` folder with utility commands (e.g., `speckit.fx2dotnet-support-core.invoke-mcp`, `speckit.fx2dotnet-support-core.get-dependency-layers`)
- `scripts/` folder with reusable helpers
- `docs/STATE_CONTRACT.md` (formatted state-file schema)
- Manifest validation report

**Duration**: 1 sprint (after Phase 1 agents are drafted)  
**Dependencies**: Phase 1 (to know what's shared)  

---

### Phase 3: Extension Manifests & Registration Model *(Can start mid-Phase 1)*

**Define final manifest for each extension**:
1. Validate YAML schema compliance (via Python ExtensionManifest class spec)
2. Verify command name patterns (must match `speckit.fx2dotnet-{ext-id}.{command}`)
3. Specify all tool requirements (Microsoft.GitHubCopilot.AppModernization.Mcp, Swick.Mcp.Fx2dotnet versions)
4. Document hook registration (which extensions register after_tasks, after_implement, etc.)
5. Define config schema and defaults

**Deliverables**:
- Completed extension.yml for all 11 extensions
- Command file existence validation (all `.md` files referenced in provides.commands exist)
- Manifest validation report (schema compliance, naming conflicts, circular dependencies)
- Hook coordination map (which extensions use which hooks)

**Duration**: 1 sprint (overlaps Phase 1 later half)  
**Dependencies**: Phase 1 (command definitions)  

---

### Phase 4: Artifact Packaging Model *(Dependent on Phase 3)*

**Define how each extension ZIP will be structured at install-time**:
1. **Bundled asset manifest** — which MCP binaries, runtime files, dependencies are in each ZIP
2. **Internal path conventions** — where commands expect to find bundled artifacts (e.g., `./artifacts/bin/fx2dotnet/`)
3. **Asset source specification** — which source files from C:\RogerBestMSFT\fx2dotnet\src\ build into each extension's artifacts
4. **Platform & runtime assumptions** — Windows-only or multi-OS; .NET runtime requirements
5. **Integrity metadata** — checksum file format, verification approach

**Deliverables**:
- Artifact manifest per extension (lists files, checksums, source origins)
- Build specification (how CI will stage artifacts into each extension folder)
- Asset path resolution logic (how commands will locate bundled artifacts at runtime)
- Packaging specification (ZIP structure, manifest placement, asset layout)

**Duration**: 1 sprint  
**Dependencies**: Phase 3  

---

### Phase 5: CI/CD Release Pipeline *(Dependent on Phase 4)*

**Implement automated build → validate → package → publish flow**:

```
┌─────────────────────────────────────┐
│ 1. Validate All Manifests           │
│    - Schema compliance              │
│    - Naming conflicts               │
│    - Circular dependencies          │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ 2. Build Required Artifacts         │
│    - Compile MCP (src/fx2dotnet)    │
│    - Collect dependencies           │
│    - Generate checksums             │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ 3. Stage Assets → Extensions        │
│    - Copy binaries into folders     │
│    - Verify paths                   │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ 4. Run Install Smoke Tests          │
│    - specify extension add --dev     │
│    - Invoke test commands           │
│    - Clean up                       │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ 5. Package Extensions (per-version) │
│    - ZIP each extension folder      │
│    - Generate SHA256 checksums      │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ 6. Publish to GitHub Releases       │
│    - Upload ZIPs                    │
│    - Upload checksums               │
│    - Create release notes           │
└────────────┬────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ 7. Update Catalogs                  │
│    - Generate/update catalog.json   │
│    - Publish to internal repo       │
│    - (Optional) mirror to community │
└─────────────────────────────────────┘
```

**Implementation**:
- **GitHub Actions workflow** (or equivalent CI service):
  - Trigger on: tag push (v{extension-id}-{version})
  - Steps: validate → build → stage → test → package → publish → catalog
  - Artifacts: Released ZIPs, checksums, catalog JSON payload
  
- **Catalog update mechanism**:
  - Generate catalog entries from extension.yml + release metadata
  - Compute download_url = GitHub release asset URL
  - Update timestamps (updated_at per extension, top-level)
  - Validate catalog structure before merge

**Deliverables**:
- GitHub Actions workflow YAML (or CI config for your platform)
- Build script (shell/PowerShell) for compiling MCP server
- Artifact staging script (copy binaries to extension folders)
- Smoke test script (install test cycle)
- Packaging script (ZIP creation + checksum generation)
- Catalog generation script (produce JSON delta from templates)
- Deployment scripts (`deploy-extensions.sh/.ps1`, `remove-extensions.sh/.ps1`) bundled with release artifacts

> **Full pipeline YAML, build scripts, staging scripts, and validation scripts**: See [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md — CI/CD Pipeline Configuration](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#cicd-pipeline-configuration) and [Build Scripts](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#build-scripts).

**Duration**: 2 sprints  
**Dependencies**: Phase 4  

---

### Phase 6: Catalog Pipeline & Install Flow *(Dependent on Phase 5)*

**Establish catalog infrastructure**:
1. **Internal install-allowed catalog** (source of truth):
   - Location: Private GitHub repo or internal artifact store
   - Content: catalog.json with install_allowed: true
   - Update: Automated by release CI
   - Access: CI token for writes; user auth for reads

2. **Community discovery catalog** (optional):
   - Mirror selected extensions to public GitHub spec-kit community catalog
   - install_allowed: false (discovery only, users install via internal link)

3. **User installation workflow**:
   - User configures `.specify/extension-catalogs.yml` to point to internal catalog
   - User runs `specify extension search fx2dotnet-assessment`
   - CLI fetches catalog, finds extension, shows info/version
   - User runs `specify extension add fx2dotnet-assessment`
   - CLI downloads ZIP from catalog.download_url, extracts, registers

**Deliverables**:
- Catalog JSON schema and example for both internal/community
- Catalog update payload generator (produces git-committable diff)
- Documentation for configuring project to use internal catalog
- Installation walkthrough (for docs)

**Duration**: 1 sprint  
**Dependencies**: Phase 5  

---

### Phase 7: Install-Time Bootstrap & Validation *(Dependent on Phase 6)*

**On `specify extension add`, ensure**:
1. **Manifest validation** — schema compliance, no conflicts
2. **Artifact presence** — all bundled binaries/runtime files exist in ZIP
3. **Command registration** — files transpiled to agent directories (`.claude/commands/`, `.copilot/commands/`, etc.)
4. **Hook registration** — entries created in `.specify/extensions.yml` with correct names/events
5. **Config template copy** — default config file created from template
6. **Skill registration** — if agent supports skills, auto-register extension commands as skills

**Deliverables**:
- Validation checklist (can be embedded in install smoke test)
- Diagnostic messages for common failures (missing artifact, bad manifest, config conflict)
- Rollback mechanism if validation fails (remove partial install)

**Duration**: Built into Phase 5 testing  
**Dependencies**: Phase 5 (smoke tests encode this)  

---

### Phase 8: Multi-Extension Orchestration Design *(Depends on Phases 1–3)*

**Define how the orchestrator extension sequences phase extensions**:

```flow
Orchestrator reads/resumes .fx2dotnet/plan.md
    ↓
Loop: For each phase:
    ↓
  Phase 1 (Assessment):
    → Invoke: speckit.fx2dotnet-assessment.run
    ← Writes: .fx2dotnet/analysis.md, .fx2dotnet/package-updates.md
    → Updates: .fx2dotnet/plan.md (lastCompletedPhase: assessment)
    ↓
  Phase 2 (Planning):
    → Invoke: speckit.fx2dotnet-planner.run
    ← Reads: .fx2dotnet/analysis.md
    → Writes: .fx2dotnet/plan.md (appends plan)
    ↓
  ... (repeat for phases 3–7)
```

**Orchestrator responsibilities**:
- Resume from interruptions (read plan.md, ask user to continue or restart)
- Enforce phase order (no out-of-sequence execution)
- Layer processing (run all projects in Layer 1 before Layer 2, etc.)
- Multi-project checkpointing (resume at exact projectId + phase, not phase-only)
- Layer fan-in gating (do not advance layer while any in-scope project remains in-progress)
- State validation (ensure required outputs exist before next phase)
- User prompts (confirm risky decisions, present uncertainties)
- Progress tracking (update plan.md after each phase completes)

**Phase extension responsibilities**:
- Read necessary state from `.fx2dotnet/` and user project
- Perform phase-specific work (calls to MCP tools, code modifications, etc.)
- Write results to expected state-file sections
- Report per-project outcomes keyed by canonical `projectId`
- Report completion status/errors
- Provide hooks for orchestration to detect failures and retry

**Deliverables**:
- Orchestrator extension specification (command signature, tool stack, state operations)
- Extension command signatures for all 7 phases
- State-file section contract (what each phase reads/writes)
- Per-project status matrix schema and resume algorithm
- Error handling and retry logic

**Duration**: 1 sprint  
**Dependencies**: Phases 1–3  

---

### Phase 9: Verification & Release Gates *(Depends on Phase 8)*

**Automated + manual verification**:

#### Automated Gates (CI pipeline):
1. **Manifest schema validation** ✓
2. **Command file existence** ✓
3. **Artifact presence in ZIP** ✓
4. **Local install smoke test** — `specify extension add --dev` each extension
5. **Command execution test** — invoke 1–2 key commands in clean project
6. **Hook registration test** — verify hooks appear in `.specify/extensions.yml`
7. **Catalog structure test** — validate generated catalog JSON
8. **Config template copying** — ensure defaults are installed

#### Manual Gates (before release):
1. **Code review** — extension.yml, command logic, config schemas
2. **Functional test** — end-to-end dry run on representative .NET Framework solution
3. **Rollback test** — install → remove → reinstall with config preservation
4. **Documentation review** — manifest descriptions, config guides, troubleshooting
5. **Catalog entry review** — version, download URL, metadata accuracy

#### End-to-End Verification Flow:
- Fresh project (`.specify/init`)
- Add internal catalog config
- Install all extensions in dependency order
- Run orchestrator command
- Verify all phases execute, state files produced, no errors
- Verify artifacts are accessible post-install
- Remove one extension, verify others still work
- Reinstall removed extension with config preserved

**Deliverables**:
- Automated test suite (bash/PowerShell scripts)
- Manual test checklist
- Verification results template (for release notes)

**Duration**: 1–2 sprints  
**Dependencies**: Phase 8  

---

### Phase 10: Versioning & Rollout Strategy

**Version management**:
- Each extension uses SemVer independently (1.0.0, 1.1.0, 2.0.0)
- Compatibility matrix published per release (which versions of extension A work with which version of B)
- spec-kit version requirement locked in `requires.speckit_version` (e.g., `>=0.2.0,<2.0.0`)

**Release checklist**:
1. Tag per-extension release: `git tag fx2dotnet-assessment-1.0.0`
2. CI builds, packages, publishes GitHub release
3. Catalog entry generated and committed
4. Release notes published (what changed, upgrade path, breaking changes)
5. Announce to team/users

**Upgrade/downgrade logic**:
- `specify extension update fx2dotnet-assessment` → upgrade to latest compatible
- `specify extension remove fx2dotnet-assessment --keep-config` → save config, remove code
- Manual reinstall of older version from external archive if needed

**Rollback strategy**:
- If release is broken: immediately yank from catalog + publish patch
- If user is stuck: `specify extension remove --keep-config` preserves configuration
- Reinstall from backup or previous GitHub release ZIP

**Deliverables**:
- Versioning policy document
- Compatibility matrix template
- Release notes template
- Upgrade/downgrade runbook

**Duration**: 1 sprint (planning); ongoing during releases  
**Dependencies**: Phases 9–10 (ready to release)  

---

## Part 3.5: Dev Installation & Local Development Flow

Throughout all implementation phases (especially Phases 1–3, 5, 8), developers will iterate on extensions locally before packaging for release. This section describes the workflow for authoring, testing, and refining extension code in a development environment.

> **Supporting implementation details** (config templates, command file templates, validation scripts, smoke test scripts): See [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md — Validation & Testing Scripts](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#validation--testing-scripts) and [Configuration Templates](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#configuration-templates).

### Development Directory Structure

Each developer working on an extension creates a local workspace:

```
C:\RogerBestMSFT\spec-kit-fx2dotnet-extensions/     # Git repo (or local dev folder)
├── fx2dotnet-assessment/
│   ├── extension.yml
│   ├── commands/
│   │   ├── run.md
│   │   └── config-help.md
│   ├── fx2dotnet-assessment-config.template.yml
│   ├── scripts/
│   │   ├── bash/
│   │   │   └── validate-projects.sh
│   │   └── powershell/
│   │       └── validate-projects.ps1
│   ├── docs/
│   │   └── IMPLEMENTATION_NOTES.md
│   └── .extensionignore               # Excludes from install ZIP
├── fx2dotnet-planner/
├── fx2dotnet-sdk-conversion/
├── fx2dotnet-package-compat/
├── fx2dotnet-multitarget/
├── fx2dotnet-web-migration/
├── fx2dotnet-build-fix/
├── fx2dotnet-project-classifier/
├── fx2dotnet-web-route-inventory/
├── fx2dotnet-support-core/
├── fx2dotnet-orchestrator/
│
├── .gitignore
├── README.md                         # Dev instructions
└── DEVELOPMENT.md                    # This flow
```

### Local Dev Workflow (Per Developer)

#### Step 1: Clone & Initialize Test Project

```bash
# Clone extension source repo
git clone https://github.com/yourorg/fx2dotnet-extensions.git
cd fx2dotnet-extensions

# Initialize a fresh spec-kit test project (separate from dev repo)
cd ~/spec-kit-test-projects
specify init --project-name fx2dotnet-test --ai copilot
cd fx2dotnet-test
```

#### Step 2: Install Extension from Dev Directory

Instead of waiting for a release, install directly from your local source:

```bash
# Install a single extension in dev mode
specify extension add --dev C:\path\to\fx2dotnet-extensions\fx2dotnet-assessment

# Verify installation
specify extension list
# Output should show: fx2dotnet-assessment (v0.0.0-dev) ... Enabled
```

**What `--dev` does**:
- Validates extension.yml syntax
- Checks manifest schema compliance
- Registers commands in agent directories (`.claude/commands/`, `.copilot/commands/`, etc.)
- Does NOT package into ZIP
- Does NOT add to registry as "installed" with version metadata
- Creates a symlink or copy-based reference to source directory
- Allows immediate code changes to take effect (on next command invocation)

#### Step 3: Test Command Registration

Verify your command is discoverable:

```bash
# In Copilot Chat or Claude editor:
/speckit.fx2dotnet-assessment.run

# If command doesn't appear:
# 1. Check .claude/commands/ exists and contains transpiled file
# 2. Verify extension.yml provides.commands has correct file path
# 3. Run manifest validation: specify extension validate fx2dotnet-assessment
```

#### Step 4: Iterate: Edit → Reinstall → Test

**Iteration loop**:
```
Developer edits extension source (commands/run.md, extension.yml, config template, etc.)
    ↓
Remove dev install (keeps config for testing): specify extension remove fx2dotnet-assessment --keep-config
    ↓
Reinstall from updated source: specify extension add --dev C:\path\to\fx2dotnet-assessment
    ↓
Re-test command in Copilot Chat: /speckit.fx2dotnet-assessment.run
    ↓
Inspect generated state files (.fx2dotnet/analysis.md) and logs
    ↓
Iterate on bugs/improvements
```

**Common iteration patterns**:

| Change | Action | Validation |
|--------|--------|-----------|
| Update command frontmatter (tools, scripts) | Remove --keep-config; reinstall | Check transpiled file has new fields |
| Fix command logic (Markdown body) | Remove --keep-config; reinstall | Re-run command; check output changes |
| Update config template | Remove --keep-config (forces copy); reinstall | Verify new config file created from template |
| Add new command to provides | Update extension.yml; reinstall | Verify new command appears in agent CLI |
| Bump version for release | Update extension.yml version; commit; tag | CI picks up tag and builds release |

#### Step 5: Validate Before Committing

Before pushing to git, run validation checks:

```bash
# Schema validation
specify extension validate fx2dotnet-assessment

# Install from clean state
rm -rf .specify/extensions/fx2dotnet-assessment
specify extension add --dev path/to/fx2dotnet-assessment

# Try a basic invocation
echo "Testing command..."
# In chat: /speckit.fx2dotnet-assessment.run (dry run / help mode)

# Check for .extensionignore to exclude junk files
cat fx2dotnet-assessment/.extensionignore
# Should exclude: .git, *.tmp, test/, node_modules/, etc.

# Commit when satisfied
git add fx2dotnet-assessment/
git commit -m "fx2dotnet-assessment: implement run command and config template"
git push origin feature/assessment-command
```

### Multi-Extension Development (Orchestrator Integration)

When testing the orchestrator extension that sequences other extensions:

#### Setup

```bash
# Install all dependent extensions in dev mode
specify extension add --dev C:\...\fx2dotnet-assessment
specify extension add --dev C:\...\fx2dotnet-planner
specify extension add --dev C:\...\fx2dotnet-sdk-conversion
specify extension add --dev C:\...\fx2dotnet-support-core

# Verify all installed
specify extension list
```

#### Test Orchestrator Sequencing

```bash
# In Copilot Chat:
/speckit.fx2dotnet-orchestrator.start --solution C:\sample\.net-framework-project.sln

# Orchestrator should:
# 1. Read/create .fx2dotnet/plan.md
# 2. Invoke assessment: /speckit.fx2dotnet-assessment.run
# 3. Wait for completion
# 4. Invoke planner: /speckit.fx2dotnet-planner.run
# 5. Update plan.md with status
# ...continue phases...

# Check progress at any time
specify extension show-state fx2dotnet                    # Shows .fx2dotnet/plan.md content
cat .fx2dotnet/plan.md                                     # Or read directly
```

#### Debug Multi-Extension Failures

```bash
# If orchestrator fails, check:
1. .fx2dotnet/plan.md — what phase failed? (lastCompletedPhase: ?)
2. Individual phase command logs — run each phase manually to isolate
3. Config files — check each extension's config template is created and valid
4. State contract — ensure each phase writes expected section to .fx2dotnet/{ProjectName}.md
```

### Config Development & Testing

#### Authoring Config Templates

Each extension ships with a template:

**File**: `fx2dotnet-assessment-config.template.yml`
```yaml
# Default Assessment Configuration
logging:
  level: info                           # info, debug, verbose
  output: console                       # console, file, none

discovery:
  scan_depth: unlimited                 # or: shallow, limited, unlimited
  include_test_projects: false
  frameworks_to_detect:                 # Whitelist frameworks of interest
    - net6.0
    - net8.0
    - netstandard2.0

output:
  format: markdown                      # markdown, json, csv
  include_dependency_graph: true
```

#### Testing Config Changes

```bash
# After modifying template:
specify extension remove fx2dotnet-assessment --keep-config
specify extension add --dev C:\...\fx2dotnet-assessment

# Verify new defaults in config file:
cat .specify/extensions/fx2dotnet-assessment/fx2dotnet-assessment-config.yml

# Run command to verify it uses new config:
/speckit.fx2dotnet-assessment.run --verbose
```

#### Config Layer Testing

Test the config resolution hierarchy (defaults → project → local → env):

```bash
# Layer 1: Defaults (from extension.yml)
cat .specify/extensions/fx2dotnet-assessment/extension.yml | grep -A 10 "defaults:"

# Layer 2: Project config
cat .specify/extensions/fx2dotnet-assessment/fx2dotnet-assessment-config.yml

# Layer 3: Local overrides (gitignored)
cat .specify/extensions/fx2dotnet-assessment/fx2dotnet-assessment-config.local.yml

# Layer 4: Environment variables
env | grep SPECKIT_FX2DOTNET_ASSESSMENT

# Test precedence:
SPECKIT_FX2DOTNET_ASSESSMENT_LOGGING_LEVEL=debug /speckit.fx2dotnet-assessment.run
# Should use env var override over file settings
```

### Testing Against Sample Solutions

#### Create Test Solutions

Prepare test `.NET Framework` solutions of varying complexity:

```
test-solutions/
├── simple-console/
│   ├── SimpleConsole.csproj          # Single .NET Framework 4.8 project
│   └── Program.cs
├── multi-layer/
│   ├── MultiLayer.sln
│   ├── Presentation.csproj           # Web project
│   ├── Business.csproj               # Library
│   ├── Data.csproj                   # EF6 library
│   └── Integration.csproj            # External integrations
├── legacy-web/
│   ├── LegacyWeb.sln
│   ├── Web.csproj                    # ASP.NET Framework web app
│   ├── Services.csproj
│   └── packages.config               # Many outdated NuGet packages
└── windows-service/
    ├── WindowsService.sln
    ├── Service.csproj                # ServiceBase-based service
    └── Installer.csproj
```

#### Run Full Assessment → Planning → SDK Conversion Flow

```bash
cd ~/spec-kit-test-projects/fx2dotnet-test

# Initialize tracking
specify init --project-name multi-layer-test

# Run orchestrator through Phase 3 (SDK conversion)
/speckit.fx2dotnet-orchestrator.start --solution ~/test-solutions/multi-layer/MultiLayer.sln --target-framework net8.0

# After completion, verify:
cat .fx2dotnet/analysis.md              # Assessment findings
cat .fx2dotnet/plan.md                  # Migration plan
cat .fx2dotnet/Business.md              # Per-project state (SDK Conversion section)

# Expected: projects normalized to SDK-style, dependency layers identified, no hard errors
```

### Smoke Test Checklist (Before Pull Request)

Before pushing code, run this checklist:

- [ ] **Manifest Validation**: `specify extension validate fx2dotnet-{name}`
- [ ] **Fresh Install**: Remove extension, reinstall from source, verify no errors
- [ ] **Command Availability**: Command appears in `/` slash menu with correct name
- [ ] **Config Template**: Default config file created on install
- [ ] **Basic Execution**: Command runs without exceptions (use --help or dry-run mode if available)
- [ ] **State Files**: Expected output files created in `.fx2dotnet/`
- [ ] **No Core Writes**: Verify no files written outside `.specify/extensions/{ext-id}` or `.fx2dotnet/`
- [ ] **Multi-Extension Coexistence**: Install multiple extensions together, verify no conflicts
- [ ] **Hook Registration** (if applicable): Check `.specify/extensions.yml` for hook entries
- [ ] **Linting & Style**: Code follows project conventions (see DEVELOPMENT.md style guide)

### Cleanup After Development

```bash
# Remove all dev extensions when done iterating
specify extension remove fx2dotnet-assessment
specify extension remove fx2dotnet-planner
# ... (remove all)

# Optionally remove test project
rm -rf ~/.specify/projects/fx2dotnet-test

# Pre-release: ensure all changes are committed
git status
# Should be clean with no uncommitted dev artifacts
```

### Dev-to-Release Handoff

When an extension is ready to release:

1. **Code Review**: PR approval required (architecture, command logic, docs)
2. **Version Bump**: Update `extension.yml` version (e.g., `0.0.0-dev` → `1.0.0`)
3. **Changelog**: Add entry to CHANGELOG.md (features, breaking changes, fixes)
4. **Tag & Push**: `git tag fx2dotnet-assessment-1.0.0 && git push origin --tags`
5. **CI Build**: Pipeline detects tag and builds release artifacts
6. **Verification**: Review release notes, checksums, catalog entry
7. **Publish**: CI publishes GitHub release and updates catalog

---

## Part 4: Artifact & Pipeline Architecture

> **Implementation details for this part** (pipeline YAML, build/staging/validation scripts, manifest templates, command templates, config templates, state contracts):
> See [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md)

### Build Output Artifacts

For each extension release, the CI pipeline produces:

```
releases/
├── fx2dotnet-assessment-1.0.0.zip
│   └── (contains extension.yml, commands/, scripts/, artifacts/, docs/)
├── fx2dotnet-assessment-1.0.0.zip.sha256
├── fx2dotnet-planner-1.0.0.zip
├── fx2dotnet-planner-1.0.0.zip.sha256
├── ... (one ZIP + checksum per extension)
├── scripts/
│   ├── deploy-extensions.sh      # Install all extensions
│   ├── deploy-extensions.ps1
│   ├── remove-extensions.sh      # Remove all extensions
│   └── remove-extensions.ps1
└── catalog.json (updated with entries for all released extensions)
```

### Catalog Entry Structure

> **Full catalog JSON example and update logic**: See [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md — CI/CD Pipeline Configuration](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#cicd-pipeline-configuration).

```json
{
  "schema_version": "1.0",
  "updated_at": "2026-04-03T15:30:00Z",
  "catalog_url": "https://internal-repo.example.com/catalogs/catalog.json",
  "extensions": {
    "fx2dotnet-assessment": {
      "id": "fx2dotnet-assessment",
      "name": "fx2dotnet Assessment",
      "version": "1.0.0",
      "description": "Discover .NET Framework projects, classify, compute dependency layers",
      "author": "YourOrg",
      "repository": "https://github.com/yourorg/fx2dotnet-extensions",
      "license": "MIT",
      "homepage": "https://github.com/yourorg/fx2dotnet-extensions/blob/main/fx2dotnet-assessment/README.md",
      "download_url": "https://github.com/yourorg/fx2dotnet-extensions/releases/download/fx2dotnet-assessment-1.0.0/fx2dotnet-assessment-1.0.0.zip",
      "requires": {
        "speckit_version": ">=0.2.0,<2.0.0",
        "tools": [
          { "name": "Microsoft.GitHubCopilot.AppModernization.Mcp", "version": ">=1.0.0", "required": true },
          { "name": "Swick.Mcp.Fx2dotnet", "version": ">=0.1.0", "required": true }
        ]
      },
      "provides": {
        "commands": 1,
        "hooks": 0
      },
      "tags": ["dotnet", "migration", "modernization", "assessment"],
      "verified": true,
      "downloads": 142,
      "stars": 5,
      "created_at": "2026-04-03T00:00:00Z",
      "updated_at": "2026-04-03T15:30:00Z"
    }
    // ... (one entry per extension in release)
  }
}
```

### MCP Tool Bundling Strategy

Since you chose **to bundle binaries in ZIP**:

**For each extension that uses MCP tools**:
1. Compile required tool from source (e.g., `src/fx2dotnet/` for Swick.Mcp.Fx2dotnet)
2. Collect dependencies (DLLs, config files, runtime files)
3. Include in ZIP under determined path (e.g., `./artifacts/bin/fx2dotnet/debug/`)
4. Commands reference via relative path exploration at runtime
5. Fail gracefully with actionable error if tool is missing

**Stored in ZIP**:
```
fx2dotnet-sdk-conversion-1.0.0.zip
├── extension.yml
├── commands/
│   └── run.md
├── artifacts/
│   └── bin/
│       └── fx2dotnet/
│           └── debug/
│               ├── Swick.Mcp.Fx2dotnet.exe
│               ├── Swick.Mcp.Fx2dotnet.deps.json
│               ├── Swick.Mcp.Fx2dotnet.runtimeconfig.json
│               └── ... (runtime files)
└── docs/
```

**At install-time**:
- ZIP extracted to `.specify/extensions/fx2dotnet-sdk-conversion/`
- Artifacts are now at `.specify/extensions/fx2dotnet-sdk-conversion/artifacts/bin/fx2dotnet/debug/`
- Commands can locate and invoke tools from extension-local paths

### Deployment & Removal Scripts

The build output includes automation scripts for deploying and removing all fx2dotnet extensions at once. These scripts enable rapid setup in CI/CD, testing environments, and team onboarding.

> **Full script code and usage examples**: See [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md — Deployment & Removal Scripts](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#deployment--removal-scripts)

#### Scripts Produced by the Pipeline

| Script | Platform | Purpose |
|--------|----------|---------|
| `scripts/deploy-extensions.sh` | Bash (Linux/macOS) | Install all extensions in dependency order |
| `scripts/deploy-extensions.ps1` | PowerShell (Windows) | Install all extensions with color-coded output |
| `scripts/remove-extensions.sh` | Bash (Linux/macOS) | Uninstall all extensions, optionally preserving config |
| `scripts/remove-extensions.ps1` | PowerShell (Windows) | Uninstall all extensions with same safety flags |
| `scripts/README-scripts.md` | — | Usage guide bundled with release |

#### Script Capabilities

Both deploy and remove scripts share a common flag set:

| Flag | Bash | PowerShell | Effect |
|------|------|-----------|--------|
| Target project directory | `--project-dir PATH` | `-ProjectDir PATH` | Target a specific Spec-Kit project |
| Version pin | `--version VERSION` | `-Version VERSION` | Install a specific/pinned extension version |
| Config preservation | `--keep-config` | `-KeepConfig` | Preserve config files during removal/reinstall |
| Preview mode | `--dry-run` | `-DryRun` | Log what would happen without making changes |

#### Extension Installation Order (Dependency-Aware)

Both deploy scripts install extensions in this fixed order:

```
1. fx2dotnet-support-core          # Must be first — shared contracts
2. fx2dotnet-project-classifier    # Required by assessment
3. fx2dotnet-assessment            # Required by planner
4. fx2dotnet-planner               # Required before conversion phases
5. fx2dotnet-build-fix             # Cross-phase; needed by sdk/multi/web
6. fx2dotnet-sdk-conversion        # Phase 3
7. fx2dotnet-package-compat        # Phase 4
8. fx2dotnet-multitarget           # Phase 5
9. fx2dotnet-web-migration         # Phase 6
10. fx2dotnet-web-route-inventory  # Support for web migration
11. fx2dotnet-orchestrator         # Last — depends on all others
```

Removal scripts operate in reverse order (orchestrator first, support-core last).

#### Integration into Build Output

CI pipeline includes deployment scripts in every release artifact bundle:

```
releases/
├── fx2dotnet-assessment-1.0.0.zip
├── ... (ZIPs for all extensions)
├── scripts/
│   ├── deploy-extensions.sh
│   ├── deploy-extensions.ps1
│   ├── remove-extensions.sh
│   ├── remove-extensions.ps1
│   └── README-scripts.md
└── catalog.json
```

#### Quick Start

```bash
# Linux/macOS — deploy all extensions
./scripts/deploy-extensions.sh --project-dir ~/my-project --version 1.0.0

# Windows — deploy all extensions
.\scripts\deploy-extensions.ps1 -ProjectDir "C:\my-project" -Version "1.0.0"

# Remove all, preserve config for reinstall
./scripts/remove-extensions.sh --keep-config

# Preview what will happen
./scripts/deploy-extensions.sh --dry-run
```

> For complete script implementations, flags reference, error handling, and CI integration examples, see [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md — Deployment & Removal Scripts](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#deployment--removal-scripts).

---

## Part 5: Key Decisions & Tradeoffs

| Decision | Chosen | Rationale | Tradeoff |
|----------|--------|-----------|----------|
| **Packaging model** | Per-agent extensions | Allows independent versioning, granular installation, parallel development | More manifests to maintain, more catalog entries |
| **Distribution** | GitHub release ZIP | Stable, versioned, reproducible, no post-install mutation | Must include all artifacts upfront; larger ZIPs |
| **Artifact bundling** | Bundled in ZIP | Self-contained install, no runtime fetch, fast offline use | ZIP size grows with binaries; platform-specific ZIPs if multi-OS desired |
| **Catalog strategy** | Internal + optional community | Control install surface, security, governance; discovery still visible | Two catalogs to maintain; manual mirroring overhead |
| **Hook strategy** | Avoid hooks between phases; use orchestrator | Deterministic sequencing, visible in code, easier debugging | Less "event-driven" feeling; orchestrator must exist |
| **State contract** | Preserve `.fx2dotnet/` semantics | Backward compatible, users can inspect/edit state, resumption works | Extensions use shared file paths instead of isolated storage |

---

## Part 6: Risks & Mitigation

| Risk | Severity | Cause | Mitigation |
|------|----------|-------|-----------|
| **MCP tool availability** | HIGH | If Microsoft.GitHubCopilot.AppModernization.Mcp is deprecated or moved | Document dependency clearly; maintain cached binary fallback; consider open-sourcing equivalent |
| **Multi-OS binary distribution** | MEDIUM | Initial plan is Windows-only; users on macOS/Linux cannot use | Start Windows-only; document platform strategy; add macOS/Linux builds in v2 if demand exists |
| **Extension versioning chaos** | MEDIUM | Users install incompatible mix of extension versions | Publish and enforce compatibility matrix; recommend "install all v1.0.0" first release |
| **ZIP size bloat** | LOW | Bundled artifacts + dependencies could exceed practical ZIP size | Monitor size per extension; consider splitting very large extensions; document size expectations |
| **Catalog sync failures** | LOW | CI publishes release but catalog update does not succeed | Catalog update as final release gate; manual verification before announcing; rollback procedure |
| **Config migration across versions** | MEDIUM | Extension v1.0 config incompatible with v2.0 | Document config changes in release notes; provide migration script if major changes |

### MCP Tool Availability Risk Handling and Replacement Options

This risk is treated as a formal continuity scenario, not a best-effort note. If the primary MCP dependency becomes unavailable, the extension suite will switch to a predefined fallback mode.

| Option | Replacement Approach | Functional Impact | Time to Activate | Target Use Case |
|--------|----------------------|-------------------|------------------|-----------------|
| Option A | Internal mirror of the same MCP package/version (private NuGet or artifact feed) | No behavioral change if package parity is preserved | Same day | Upstream outage, rate limiting, or package pull failures |
| Option B | Organization-maintained compatibility fork implementing the same tool contracts | Low to medium impact depending on feature parity | 1-2 weeks | Upstream deprecation or breaking API/version change |
| Option C | Hybrid replacement: use Swick.Mcp.Fx2dotnet + extension-native analyzers/scripts for missing AppModernization capabilities | Medium impact; reduced automation for SDK conversion edge cases | 1-2 sprints | Extended upstream unavailability where full parity is not practical |
| Option D | Controlled manual mode: planner/build-fix driven workflow without unavailable MCP calls | Highest impact; more human decision points | Same day | Emergency fallback to unblock active migration projects |

#### Activation Policy

1. Trigger fallback mode if MCP resolution fails for 2 consecutive pipeline runs or 2 consecutive production install windows.
2. Start with Option A by default.
3. Escalate to Option B if outage exceeds 5 business days or if package is withdrawn/deprecated.
4. Escalate to Option C when parity work for Option B is not feasible in required timeline.
5. Use Option D only as emergency continuity mode for in-flight modernization work.

#### Ownership and Verification

1. Owner: release engineering (pipeline fallback), migration platform owner (tool contract parity), and extension maintainer (command behavior validation).
2. Every fallback activation requires a smoke run on a sample .NET Framework solution and a published note in release artifacts.
3. Fallback mode must be explicitly visible in release notes and in extension diagnostics output.

> Implementation-level procedures, scripts, and contract adapters for these options are documented in [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md — MCP Availability Continuity Runbook](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md#mcp-availability-continuity-runbook).

---

## Part 7: Success Criteria & Verification

### Installation Verification

**✓ Automated Checks (CI pipeline)**:
- [ ] All extension manifests validate against schema
- [ ] All command files referenced in manifests exist
- [ ] All bundled artifact files exist in staged extension folders
- [ ] Smoke install succeeds without errors (`specify extension add --dev`)
- [ ] Transpiled commands appear in agent directories (`.claude/commands/`, etc.)
- [ ] Hooks registered in `.specify/extensions.yml`
- [ ] Config templates copied to extension folders
- [ ] All 11 extensions install successfully in sequence

**✓ Manual Checks (release gate)**:
- [ ] User can run `specify extension search fx2dotnet` and find results
- [ ] User can run `specify extension add fx2dotnet-assessment` from catalog
- [ ] After install, user can run `/speckit.fx2dotnet-assessment.run` in Copilot Chat
- [ ] Command executes and produces expected `.fx2dotnet/analysis.md`
- [ ] User can remove extension (preserving config) and reinstall
- [ ] All 11 extensions coexist peacefully without command conflicts
- [ ] Same-name project collision scenario (e.g., `src/Web/Web.csproj` and `legacy/Web/Web.csproj`) produces distinct, stable state outputs

### Functional Verification

**✓ End-to-End Migration Dry Run**:
- [ ] Fresh Spec-Kit project with .NET Framework solution
- [ ] Install all fx2dotnet extensions
- [ ] Run orchestrator command: `/speckit.fx2dotnet-orchestrator.start`
- [ ] Assessment phase completes, writes analysis.md and package-updates.md
- [ ] Planning phase completes, appends plan to plan.md
- [ ] SDK conversion phase processes all projects, layers complete successfully
- [ ] Package compatibility phase updates packages without errors
- [ ] Multitarget phase adds target frameworks
- [ ] Web migration phase (if applicable) creates ASP.NET Core skeleton
- [ ] Final state files contain expected sections and metadata
- [ ] User can inspect `.fx2dotnet/` directory and understand workflow progress
- [ ] Interrupt and resume test continues from exact projectId + phase checkpoint in a multi-project solution
- [ ] Layer gating test proves no Layer N+1 execution starts before Layer N projects resolve
- [ ] Cross-file project set validation passes (`analysis.md`, `plan.md`, `package-updates.md`, per-project files reference identical projectId inventory)

**✓ Artifact Integrity**:
- [ ] All bundled MCP tool binaries are present post-install
- [ ] Commands can locate and invoke MCP tools without errors
- [ ] Checksum validation passes for released ZIPs
- [ ] Catalog JSON is valid spec-kit catalog schema v1.0

---

## Part 8: Implementation Timeline

```
Sprint 1 (Week 1):
  ├─ Phase 0: Architecture lock & contract definition
  └─ Begins Phase 1: Per-agent manifest drafting (parallel)

Sprint 2–3 (Weeks 2–3):
  ├─ Phase 1: Complete all 10–11 agent extension manifests
  ├─ Phase 2: Shared support extension
  ├─ Phase 3: Manifest validation & finalization
  └─ Begins Phase 4: Artifact packaging design

Sprint 4 (Week 4):
  ├─ Phase 4: Complete artifact/packaging spec
  ├─ Phase 5: Build CI/CD pipeline (GitHub Actions workflow, build scripts, publish automation)
  └─ Begins Phase 9: Verification script authoring

Sprint 5–6 (Weeks 5–6):
  ├─ Phase 5: Complete & test CI pipeline in staging
  ├─ Phase 6: Catalog infrastructure setup
  ├─ Phase 7: Install-time bootstrap validation
  └─ Phase 9: Run initial verification gates

Sprint 7 (Week 7):
  ├─ Phase 8: Multi-extension orchestration refinement
  ├─ Phase 9: Full end-to-end test cycles
  ├─ Phase 10: Release checklist & versioning policy
  └─ Iteration on failures & fixes

Sprint 8+ (Weeks 8+):
  ├─ Manual release gate walkthroughs
  ├─ Documentation finalization
  ├─ Internal release to team
  └─ Iterate on feedback before public release

**Total**: 8 weeks (2 months) for full implementation + release readiness.
**Parallelization**: Phases 1, 3, 4 can overlap; Phases 5+6 can overlap.
```

---

## Part 9: Handoff & Next Steps

### For Approval

Before implementation begins, confirm:
1. **Architecture locked** — 11 extension packages + 1 support package confirmed?
2. **Orchestrator approach** — Single orchestrator extension vs. distributed triggering?
3. **MCP bundling strategy** — Confirmed binaries bundled in ZIP (Windows-only initially)?
4. **Catalog targets** — Internal install-allowed catalog confirmed as primary?
5. **Timeline feasibility** — 8-week estimate acceptable?

### For Implementation Kickoff

Once approved:
1. Create directory structure under spec-kit: `spec-kit/extensions/fx2dotnet-{assessment,planner,...}`
2. Author initial Phase 0 contract document (extension IDs, command names, state sections)
3. Assign teams to parallel Phase 1 agent drafting
4. Set up GitHub Actions workflow skeleton
5. Establish internal catalog repository/storage location

### For Ongoing Maintenance

- **Manifest versioning**: Keep extension.yml locked for each release (no mid-release changes)
- **Backward compatibility**: Always maintain at least one prior major version for upgrades
- **Catalog discipline**: Automated generation + manual review before merge
- **Testing automation**: Smoke test suite runs on every catalog publish

---

## Appendix: Referenced Source Files

### From C:\RogerBestMSFT\fx2dotnet

- [agents/dotnet-fx-to-modern-dotnet.md](agents/dotnet-fx-to-modern-dotnet.md) — Orchestrator workflow
- [agents/assessment.agent.md](agents/assessment.agent.md) — Phase 1 behavior
- [agents/migration-planner.agent.md](agents/migration-planner.agent.md) — Phase 2 behavior
- [agents/sdk-project-conversion.agent.md](agents/sdk-project-conversion.agent.md) — Phase 3 behavior
- [agents/package-compat-core.agent.md](agents/package-compat-core.agent.md) — Phase 4 behavior
- [agents/multitarget.agent.md](agents/multitarget.agent.md) — Phase 5 behavior
- [agents/aspnet-framework-to-aspnetcore-web-migration.agent.md](agents/aspnet-framework-to-aspnetcore-web-migration.agent.md) — Phase 6 behavior
- [agents/build-fix.agent.md](agents/build-fix.agent.md) — Cross-phase remediation
- [agents/project-type-detector.agent.md](agents/project-type-detector.agent.md) — Type detection support
- [agents/legacy-web-route-inventory.agent.md](agents/legacy-web-route-inventory.agent.md) — Route discovery support
- [skills/ef6-migration-policy/SKILL.md](skills/ef6-migration-policy/SKILL.md) — EF6 policy
- [skills/systemweb-adapters/SKILL.md](skills/systemweb-adapters/SKILL.md) — System.Web adapter policy
- [skills/owin-identity/SKILL.md](skills/owin-identity/SKILL.md) — OWIN/Identity policy
- [skills/windows-service-migration/SKILL.md](skills/windows-service-migration/SKILL.md) — Service policy
- [.mcp.json](.mcp.json) — MCP server bootstrap
- [plugin.json](plugin.json) — Current plugin metadata
- [src/fx2dotnet/Tools.cs](src/fx2dotnet/Tools.cs) — MCP tool definitions

### From C:\spec-kit-main\spec-kit-main

- [extensions/RFC-EXTENSION-SYSTEM.md](extensions/RFC-EXTENSION-SYSTEM.md) — Full spec-kit extension system design
- [extensions/EXTENSION-API-REFERENCE.md](extensions/EXTENSION-API-REFERENCE.md) — Manifest schema & Python API
- [extensions/EXTENSION-DEVELOPMENT-GUIDE.md](extensions/EXTENSION-DEVELOPMENT-GUIDE.md) — Dev workflow
- [extensions/EXTENSION-PUBLISHING-GUIDE.md](extensions/EXTENSION-PUBLISHING-GUIDE.md) — Release & catalog procedures
- [src/specify_cli/extensions.py](src/specify_cli/extensions.py) — Extension manager source (ExtensionManager, ExtensionCatalog, ConfigManager, HookExecutor classes)

---

## Document Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| Architect | TBD | — | Pending Review |
| Tech Lead | TBD | — | Pending Review |
| Release PM | TBD | — | Pending Review |

**Approved For Implementation**: [ ] Yes [ ] No [ ] Conditional (see comments)

**Comments/Concerns**:
```
[Reviewer notes here]
```

---

**Document Version History**:
- v1.0 — Initial draft — April 3, 2026
