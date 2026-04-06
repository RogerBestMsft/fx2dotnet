# Spec-Kit fx2dotnet Extension Suite Work Items

**Document Version**: 1.0  
**Date**: April 3, 2026  
**Purpose**: Execution backlog for the Spec-Kit fx2dotnet extension-suite effort. This document converts the approved plan and implementation details into trackable work items without starting implementation.

> **Source documents**: [SPEC_KIT_EXTENSION_PLAN.md](SPEC_KIT_EXTENSION_PLAN.md) and [SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md](SPEC_KIT_EXTENSION_IMPLEMENTATION_DETAILS.md)

---

## Status Legend

- `Not Started` - defined but not underway
- `In Progress` - actively being executed
- `Blocked` - cannot proceed until a dependency or decision is resolved
- `Done` - completed and verified against exit criteria

---

## Tracking Summary

| ID | Work Item | Status | Depends On | Primary Outputs |
|----|-----------|--------|------------|-----------------|
| WI-01 | Lock extension architecture | Done | None | Locked extension topology and boundaries |
| WI-02 | Lock command and state contracts | Done | WI-01 | Command names, ownership, state contract |
| WI-03 | Decide shared skill ownership | Done | WI-01 | Shared-vs-local skill mapping |
| WI-04 | Author support-core extension | Done | WI-02, WI-03 | `fx2dotnet-support-core/` assets |
| WI-05 | Author project-classifier extension | Done | WI-02 | `fx2dotnet-project-classifier/` assets |
| WI-06 | Author assessment extension | Done | WI-02, WI-04, WI-05 | `fx2dotnet-assessment/` assets |
| WI-07 | Author planner extension | Done | WI-02, WI-06 | `fx2dotnet-planner/` assets |
| WI-08 | Author build-fix extension | Done | WI-02, WI-04 | `fx2dotnet-build-fix/` assets |
| WI-09 | Author sdk-conversion extension | Done | WI-02, WI-04, WI-06, WI-08 | `fx2dotnet-sdk-conversion/` assets |
| WI-10 | Author package-compat extension | Done | WI-02, WI-04, WI-06, WI-07, WI-08 | `fx2dotnet-package-compat/` assets |
| WI-11 | Author multitarget extension | Done | WI-02, WI-07, WI-08, WI-09, WI-10 | `fx2dotnet-multitarget/` assets |
| WI-12 | Author web-route-inventory extension | Done | WI-02, WI-04, WI-06 | `fx2dotnet-web-route-inventory/` assets |
| WI-13 | Author web-migration extension | Done | WI-02, WI-07, WI-08, WI-11, WI-12 | `fx2dotnet-web-migration/` assets |
| WI-14 | Author orchestrator extension | Done | WI-02, WI-04, WI-06, WI-07, WI-09, WI-10, WI-11, WI-13 | `fx2dotnet-orchestrator/` assets |
| WI-15 | Validate manifests and hooks | Done | WI-04 through WI-14 | `docs/release/manifest-validation-report.md`, `docs/release/hook-coordination-map.md`, `scripts/validate-extensions.ps1` |
| WI-16 | Define artifact packaging model | Done | WI-15 | `packaging/artifact-manifests/`, `packaging/README.md`, `docs/release/artifact-packaging-model.md` |
| WI-17 | Build CI and release pipeline | Done | WI-16 | `.github/workflows/ci.yml`, `.github/workflows/release-extensions.yml`, `scripts/build-mcp.ps1`, `scripts/stage-artifacts.ps1`, `scripts/package-extension.ps1` |
| WI-18 | Implement catalog install flow | Done | WI-17 | `catalogs/catalog.json`, `catalogs/community-catalog.json`, `scripts/generate-catalog.ps1`, `docs/release/catalog-install-flow.md` |
| WI-19 | Define bootstrap and rollback checks | Done | WI-17, WI-18 | `scripts/smoke-test.ps1`, `scripts/deploy-extensions.ps1`, `scripts/remove-extensions.ps1`, `docs/release/bootstrap-and-rollback-checks.md` |
| WI-20 | Define phase sequencing behavior | Done | WI-06 through WI-14 | `docs/release/phase-sequencing-contract.md` |
| WI-21 | Build verification and release gates | Done | WI-15 through WI-20 | `docs/release/verification-and-release-gates.md`, `.github/workflows/ci.yml` |
| WI-22 | Write versioning and rollout docs | Done | WI-21 | `docs/release/versioning-and-rollout.md`, `scripts/README-scripts.md` |

---

## Workstreams

### Workstream A: Foundation Decisions

#### WI-01 - Lock extension architecture

- **Goal**: Finalize the extension topology, ownership boundaries, and dependency model.
- **Source**: Plan Part 2 and Phase 0.
- **Scope**:
  - Confirm the 11-extension model.
  - Confirm orchestrator-led sequencing.
  - Confirm hard boundaries such as no core writes, no command shadowing, and isolated install packages.
- **Exit criteria**:
  - Extension list is fixed.
  - Dependency relationships are agreed.
  - Architectural assumptions no longer change extension scope.

#### WI-02 - Lock command and state contracts

- **Goal**: Define stable command names, command signatures, and `.fx2dotnet/*.md` ownership rules.
- **Source**: Plan Part 2, Phase 0, Phase 8, and implementation state contract sections.
- **Scope**:
  - Finalize command naming convention.
  - Assign read/write ownership for `plan.md`, `analysis.md`, `package-updates.md`, and per-project state files.
  - Define uncertainty markers and phase gate expectations.
  - Define canonical `projectId` format (solution-relative `.csproj` path) and deterministic project ordering rules.
  - Define collision-safe per-project state file naming for same-name projects.
- **Exit criteria**:
  - Every extension has a stable command surface.
  - Every state section has a single owning extension.
  - Cross-extension read/write expectations are documented.
  - `projectId` identity and file-collision rules are documented and approved.

#### WI-03 - Decide shared skill ownership

- **Goal**: Decide which migration policies remain shared and which belong inside individual extensions.
- **Source**: Plan Phase 0, current `skills/` folder, and extension responsibility boundaries.
- **Scope**:
  - Inventory each existing skill and classify it as shared operational policy, phase-specific policy, or reference-only content.
  - Assign a single ownership target for each skill: support-core, one phase extension, or documentation-only retention.
  - Define invocation boundaries so no two extensions assume ownership of the same behavior.
  - Define discovery trigger expectations for each owned skill surface.
- **Inputs**:
  - Existing skill directories and `SKILL.md` files under `skills/`.
  - Extension boundaries defined by WI-01 and state/command contracts defined by WI-02.
  - Per-extension responsibilities from the implementation map.
- **Detailed tasks**:
  1. Build a skill inventory table with columns: skill, current location, current purpose, dependencies, and current consumers.
  2. For each skill, decide ownership using this rule: if it applies to multiple phases with identical behavior, place in shared support; if it constrains one phase workflow, place with that phase extension.
  3. Document trigger phrases and "use when" language so skill discovery is deterministic.
  4. Mark reference assets that should not be executable skills and keep them as docs only.
  5. Identify overlap conflicts where two skills encode conflicting policy and define precedence.
  6. Produce a migration plan for any skill relocations so downstream extension authoring can consume a stable map.
- **Proposed ownership baseline**:
  - `ef6-migration-policy`: shared policy consumed by planner, package-compat, and multitarget.
  - `systemweb-adapters`: web-migration owned policy, with reference docs retained.
  - `windows-service-migration`: project-classifier + planner policy (shared with classifier as discovery, planner as execution constraint).
  - `owin-identity`: web-migration policy with planner cross-reference.
  - Placeholder skill folders: classify as deferred and document as not in active scope.
- **Required outputs**:
  - Skill ownership matrix in the form: skill -> owner extension -> consumers -> trigger phrases -> precedence.
  - Conflict resolution rules for overlapping policies.
  - Reference-only list for non-executable guidance assets.
  - Change log entry recording ownership decisions and rationale.
- **Dependencies**:
  - WI-01 must be completed so extension boundaries are stable.
  - WI-02 should be completed so command/state ownership aligns with skill ownership.
- **Risks and mitigations**:
  - Risk: a shared skill becomes too broad and causes unintended invocation.
  - Mitigation: narrow trigger phrases and bind usage to explicit extension commands.
  - Risk: policy duplicated across extensions and diverges over time.
  - Mitigation: enforce single canonical owner and consumer-only references.
  - Risk: low discoverability due to weak `description` wording.
  - Mitigation: standardize "Use when" phrasing and include phase keywords.
- **Exit criteria**:
  - Shared vs. per-extension policy ownership is documented and approved.
  - No skill is left ambiguous across multiple extensions.
  - Every in-scope skill has explicit triggers and precedence behavior.
  - WI-04 through WI-14 can consume the matrix without re-deciding skill placement.

### Workstream B: Extension Authoring

#### WI-04 - Author support-core extension

- **Goal**: Create the shared support extension used by the rest of the suite.
- **Source**: Plan support-core section and implementation map item 1.
- **Required outputs**:
  - `extension.yml`
  - `commands/validate-state-contract.md`
  - `commands/resolve-solution-context.md`
  - `commands/invoke-mcp-wrapper.md`
  - `docs/state-contract.md`
  - `docs/shared-conventions.md`
  - shared Bash and PowerShell helper scripts
  - `fx2dotnet-support-core-config.template.yml`
- **Exit criteria**:
  - Shared helpers cover contract validation, path resolution, and MCP wrapper behavior.
  - Other extensions can depend on it without redefining common utilities.

#### WI-05 - Author project-classifier extension

- **Goal**: Create the project typing and SDK-eligibility extension.
- **Source**: Plan project-classifier section and implementation map item 2.
- **Required outputs**:
  - `extension.yml`
  - classification commands
  - `docs/classification-rules.md`
  - project metadata scan scripts
  - `fx2dotnet-project-classifier-config.template.yml`
- **Exit criteria**:
  - Classification outputs are deterministic or explicitly marked for user confirmation.

#### WI-06 - Author assessment extension

- **Goal**: Create the phase-1 discovery extension.
- **Source**: Plan assessment section and implementation map item 3.
- **Required outputs**:
  - `extension.yml`
  - `commands/run.md`
  - `commands/compute-layers.md`
  - `commands/collect-package-baseline.md`
  - `docs/assessment-output-format.md`
  - solution validation scripts
  - staged MCP artifacts
  - `fx2dotnet-assessment-config.template.yml`
- **Exit criteria**:
  - Produces `.fx2dotnet/analysis.md` and seed `.fx2dotnet/package-updates.md` according to contract.

#### WI-07 - Author planner extension

- **Goal**: Create the plan synthesis extension.
- **Source**: Plan planner section and implementation map item 4.
- **Required outputs**:
  - `extension.yml`
  - `commands/generate-plan.md`
  - `commands/summarize-risks.md`
  - `docs/planning-rules.md`
  - `fx2dotnet-planner-config.template.yml`
- **Exit criteria**:
  - Consumes assessment outputs and writes a valid `.fx2dotnet/plan.md` execution plan.

#### WI-08 - Author build-fix extension

- **Goal**: Create the cross-phase remediation extension.
- **Source**: Plan build-fix section and implementation map item 5.
- **Required outputs**:
  - `extension.yml`
  - `commands/diagnose-build.md`
  - `commands/apply-fix-pattern.md`
  - `commands/retry-build.md`
  - `docs/build-failure-taxonomy.md`
  - build scripts
  - `fx2dotnet-build-fix-config.template.yml`
- **Exit criteria**:
  - Supports bounded retries and writes project-scoped `## Build Fix` state.

#### WI-09 - Author sdk-conversion extension

- **Goal**: Create the SDK normalization extension.
- **Source**: Plan sdk-conversion section and implementation map item 6.
- **Required outputs**:
  - `extension.yml`
  - `commands/convert-project.md`
  - `commands/validate-conversion.md`
  - `commands/normalize-project-file.md`
  - `docs/sdk-conversion-rules.md`
  - staged MCP artifacts
  - `fx2dotnet-sdk-conversion-config.template.yml`
- **Exit criteria**:
  - Records per-project SDK conversion state and stops correctly on per-project failure.

#### WI-10 - Author package-compat extension

- **Goal**: Create the chunked package compatibility extension.
- **Source**: Plan package-compat section and implementation map item 7.
- **Required outputs**:
  - `extension.yml`
  - `commands/apply-package-chunk.md`
  - `commands/validate-package-updates.md`
  - `commands/record-package-status.md`
  - `docs/package-risk-model.md`
  - staged MCP artifacts
  - `fx2dotnet-package-compat-config.template.yml`
- **Exit criteria**:
  - Updates `.fx2dotnet/package-updates.md` as an execution ledger with stop conditions for risky substitutions.

#### WI-11 - Author multitarget extension

- **Goal**: Create the incremental multitargeting extension.
- **Source**: Plan multitarget section and implementation map item 8.
- **Required outputs**:
  - `extension.yml`
  - `commands/add-target-frameworks.md`
  - `commands/validate-api-gaps.md`
  - `commands/record-multitarget-state.md`
  - `docs/multitarget-strategy.md`
  - `fx2dotnet-multitarget-config.template.yml`
- **Exit criteria**:
  - Writes `## Multitarget` project state and pauses on unresolved API compatibility decisions.

#### WI-12 - Author web-route-inventory extension

- **Goal**: Create the legacy web route discovery extension.
- **Source**: Plan web-route-inventory section and implementation map item 9.
- **Required outputs**:
  - `extension.yml`
  - route, handler, and module inventory commands
  - `docs/route-inventory-output.md`
  - `fx2dotnet-web-route-inventory-config.template.yml`
- **Exit criteria**:
  - Produces inventory artifacts suitable for downstream web-host migration.

#### WI-13 - Author web-migration extension

- **Goal**: Create the side-by-side ASP.NET Core host migration extension.
- **Source**: Plan web-migration section and implementation map item 10.
- **Required outputs**:
  - `extension.yml`
  - `commands/scaffold-core-host.md`
  - `commands/port-routes.md`
  - `commands/validate-web-host.md`
  - web migration docs
  - `fx2dotnet-web-migration-config.template.yml`
- **Exit criteria**:
  - Writes `## Web Migration` project state and preserves side-by-side migration behavior.

#### WI-14 - Author orchestrator extension

- **Goal**: Create the control-plane extension that sequences the suite.
- **Source**: Plan orchestrator section, Phase 8, and implementation map item 11.
- **Required outputs**:
  - `extension.yml`
  - `commands/start.md`
  - `commands/resume.md`
  - `commands/show-status.md`
  - `commands/validate-phase-gates.md`
  - `docs/orchestration-lifecycle.md`
  - per-project phase status matrix schema and checkpoint format (keyed by `projectId`)
  - `fx2dotnet-orchestrator-config.template.yml`
- **Exit criteria**:
  - Orchestrator command surface is stable and aligned to phase outputs and resume behavior.
  - Resume semantics are validated at project granularity (`projectId` + phase), not phase-only.

### Workstream C: Platform, Packaging, and Registration

#### WI-15 - Validate manifests and hooks

- **Goal**: Validate all extension manifests, command registrations, and hook usage.
- **Source**: Plan Phase 3 and implementation manifest template guidance.
- **Scope**:
  - YAML schema compliance
  - command file existence
  - naming conflict detection
  - dependency and circular reference checks
  - hook coordination map
- **Exit criteria**:
  - All extension manifests validate cleanly.
  - Hook behavior is intentional and documented.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [docs/release/manifest-validation-report.md](docs/release/manifest-validation-report.md), [docs/release/hook-coordination-map.md](docs/release/hook-coordination-map.md), [scripts/validate-extensions.ps1](scripts/validate-extensions.ps1)

#### WI-16 - Define artifact packaging model

- **Goal**: Define how MCP binaries and other runtime assets are bundled per extension.
- **Source**: Plan Phase 4 and implementation build/staging sections.
- **Scope**:
  - artifact manifests per extension
  - source-to-artifact mapping
  - runtime path resolution rules
  - ZIP structure and integrity metadata
- **Exit criteria**:
  - Packaging layout is consistent and sufficient for install-time execution.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [packaging/README.md](packaging/README.md), [docs/release/artifact-packaging-model.md](docs/release/artifact-packaging-model.md), [packaging/artifact-manifests](packaging/artifact-manifests)

#### WI-17 - Build CI and release pipeline

- **Goal**: Implement validation, build, stage, package, publish, and catalog update automation.
- **Source**: Plan Phase 5 and implementation CI/CD section.
- **Required outputs**:
  - workflow YAML
  - MCP build script
  - artifact staging script
  - packaging script
  - smoke test script
  - catalog generation/update script
  - deploy/remove extension scripts
- **Exit criteria**:
  - Pipeline can produce releasable extension ZIPs and associated metadata.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [.github/workflows/ci.yml](.github/workflows/ci.yml), [.github/workflows/release-extensions.yml](.github/workflows/release-extensions.yml), [scripts/build-mcp.ps1](scripts/build-mcp.ps1), [scripts/stage-artifacts.ps1](scripts/stage-artifacts.ps1), [scripts/package-extension.ps1](scripts/package-extension.ps1)

#### WI-18 - Implement catalog install flow

- **Goal**: Establish internal catalog distribution and installation guidance.
- **Source**: Plan Phase 6 and implementation catalog/pipeline examples.
- **Scope**:
  - catalog JSON structure
  - internal install-allowed catalog behavior
  - optional community discovery mirror
  - user install walkthrough
- **Exit criteria**:
  - Catalog entries can be generated and used by `specify extension search/add` workflows.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [catalogs/catalog.json](catalogs/catalog.json), [catalogs/community-catalog.json](catalogs/community-catalog.json), [scripts/generate-catalog.ps1](scripts/generate-catalog.ps1), [docs/release/catalog-install-flow.md](docs/release/catalog-install-flow.md)

#### WI-19 - Define bootstrap and rollback checks

- **Goal**: Define install-time validation, diagnostics, and rollback behavior.
- **Source**: Plan Phase 7 and implementation smoke/validation scripts.
- **Scope**:
  - manifest validation
  - artifact presence checks
  - command and hook registration checks
  - config template copy checks
  - rollback conditions for partial installs
- **Exit criteria**:
  - Failure modes and rollback expectations are documented and testable.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [docs/release/bootstrap-and-rollback-checks.md](docs/release/bootstrap-and-rollback-checks.md), [scripts/smoke-test.ps1](scripts/smoke-test.ps1), [scripts/deploy-extensions.ps1](scripts/deploy-extensions.ps1), [scripts/remove-extensions.ps1](scripts/remove-extensions.ps1)

### Workstream D: Workflow Control and Release Readiness

#### WI-20 - Define phase sequencing behavior

- **Goal**: Finalize orchestrator-to-phase sequencing, resume semantics, and retry boundaries.
- **Source**: Plan Phase 8.
- **Scope**:
  - phase invocation order
  - gating rules
  - layer-by-layer processing expectations
  - fan-out/fan-in behavior per dependency layer
  - explicit rule: no Layer N+1 execution while any Layer N project is `in-progress`
  - resume pointer format keyed by `projectId` + phase
  - completion signaling and failure escalation
- **Exit criteria**:
  - Orchestration contract is explicit enough to implement without ambiguity.
  - Multi-project sequencing and resume behavior are deterministic and testable.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [docs/release/phase-sequencing-contract.md](docs/release/phase-sequencing-contract.md)

#### WI-21 - Build verification and release gates

- **Goal**: Define the automated and manual verification model required before release.
- **Source**: Plan Phase 9 and implementation validation/testing scripts.
- **Scope**:
  - install smoke tests
  - command execution tests
  - catalog validation
  - functional dry run against sample solutions
  - same-name project collision test (distinct per-project state outputs)
  - interrupt/resume continuity test from exact `projectId` + phase checkpoint
  - cross-file `projectId` inventory consistency test (`analysis.md`, `plan.md`, `package-updates.md`, per-project files)
  - rollback and reinstall tests
- **Exit criteria**:
  - Gate suite is defined for CI and human release review.
  - Multi-project correctness gates are included and pass in release validation.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [docs/release/verification-and-release-gates.md](docs/release/verification-and-release-gates.md), [.github/workflows/ci.yml](.github/workflows/ci.yml)

#### WI-22 - Write versioning and rollout docs

- **Goal**: Document versioning, compatibility, release, upgrade, and rollback policy.
- **Source**: Plan Phase 10.
- **Scope**:
  - independent SemVer policy
  - compatibility matrix template
  - release notes template
  - upgrade and downgrade guidance
  - rollback runbook
- **Exit criteria**:
  - Release management expectations are documented and usable by maintainers.
- **Execution**:
  - Owner: GitHub Copilot
  - Started: 2026-04-03
  - Completed: 2026-04-03
  - Artifacts: [docs/release/versioning-and-rollout.md](docs/release/versioning-and-rollout.md), [scripts/README-scripts.md](scripts/README-scripts.md)

---

## Recommended Execution Order

1. Complete WI-01 through WI-03 before authoring extensions.
2. Parallelize WI-04 through WI-14 where dependencies allow.
3. Run WI-15 before finalizing packaging and pipeline assumptions.
4. Complete WI-16 through WI-19 before attempting release distribution.
5. Complete WI-20 through WI-22 before declaring the suite release-ready.

---

## Tracking Notes

- This document is intended for execution tracking and status updates.
- Implementation details remain in the companion documents; this file should track scope, dependencies, and completion state.
- When execution begins, each work item should be updated with owner, start date, completion date, and links to implementation artifacts or pull requests.