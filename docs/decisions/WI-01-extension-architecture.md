# WI-01: Extension Architecture Decision Record

**Status**: Done  
**Date**: April 3, 2026  
**Depends On**: None  

---

## Decision

The fx2dotnet workflow is packaged as **11 independent, installable Spec-Kit extensions** using a per-agent model with one shared support extension. This decision is locked and no longer subject to scope changes.

---

## Locked Extension List

| Extension ID | Role | Phase |
|---|---|---|
| `fx2dotnet-support-core` | Shared utilities, state contract docs, MCP wrappers | Foundation |
| `fx2dotnet-project-classifier` | Project type detection and SDK eligibility | Support |
| `fx2dotnet-assessment` | Phase 1 — solution discovery and inventory | Phase 1 |
| `fx2dotnet-planner` | Phase 2 — migration plan synthesis | Phase 2 |
| `fx2dotnet-build-fix` | Cross-phase — iterative build remediation | Cross-phase |
| `fx2dotnet-sdk-conversion` | Phase 3 — SDK-style project normalization | Phase 3 |
| `fx2dotnet-package-compat` | Phase 4 — chunked package compatibility updates | Phase 4 |
| `fx2dotnet-multitarget` | Phase 5 — incremental multitargeting | Phase 5 |
| `fx2dotnet-web-route-inventory` | Support — legacy ASP.NET route extraction | Support |
| `fx2dotnet-web-migration` | Phase 6 — side-by-side ASP.NET Core host migration | Phase 6 |
| `fx2dotnet-orchestrator` | Control plane — sequences all phases with resume support | Orchestration |

Total: **11 extensions**. This count is final.

---

## Sequencing Model

**Orchestrator-led sequencing**: `fx2dotnet-orchestrator` is the single control-plane extension responsible for driving phase execution and enforcing order. Phase extensions do not trigger each other directly.

Execution order enforced by orchestrator:
1. Assessment → Planning → SDK Conversion → Package Compat → Multitarget → Web Migration → Final Build

Support extensions (`project-classifier`, `web-route-inventory`) are invoked on demand by phase commands — not by the orchestrator directly.

---

## Hard Boundaries (Non-Negotiable)

1. **No spec-kit core file writes**: All commands, config, scripts, and assets live under `.specify/extensions/{extension-id}/` after installation.
2. **No command shadowing**: Every command follows `speckit.fx2dotnet-{ext-id}.{command}` pattern; no conflicts with core spec-kit commands are permitted.
3. **Sealed state contract**: `.fx2dotnet/*.md` state files are produced only via extension commands; no direct file manipulation from hooks or scripts.
4. **Isolated installation packages**: Each extension ZIP is self-contained; no shared build artifacts or post-install fetches.
5. **Version independence**: Each extension is versioned independently using SemVer; no "release all together" requirement.
6. **No hooks between phase extensions**: Phase sequencing uses explicit orchestrator command invocations, not hook chains between peer extensions.

---

## Dependency Relationships

```
fx2dotnet-orchestrator
  └── depends on: all phase extensions

fx2dotnet-assessment
  └── depends on: fx2dotnet-support-core, fx2dotnet-project-classifier

fx2dotnet-planner
  └── depends on: fx2dotnet-support-core, fx2dotnet-assessment

fx2dotnet-build-fix
  └── depends on: fx2dotnet-support-core

fx2dotnet-sdk-conversion
  └── depends on: fx2dotnet-support-core, fx2dotnet-assessment, fx2dotnet-build-fix

fx2dotnet-package-compat
  └── depends on: fx2dotnet-support-core, fx2dotnet-assessment, fx2dotnet-planner, fx2dotnet-build-fix

fx2dotnet-multitarget
  └── depends on: fx2dotnet-planner, fx2dotnet-build-fix, fx2dotnet-sdk-conversion, fx2dotnet-package-compat

fx2dotnet-web-route-inventory
  └── depends on: fx2dotnet-support-core, fx2dotnet-assessment

fx2dotnet-web-migration
  └── depends on: fx2dotnet-planner, fx2dotnet-build-fix, fx2dotnet-multitarget, fx2dotnet-web-route-inventory

fx2dotnet-support-core
  └── no internal dependencies

fx2dotnet-project-classifier
  └── no internal dependencies
```

---

## Exit Criteria — Satisfied

- [x] Extension list is fixed at 11 extensions
- [x] Dependency relationships documented and agreed
- [x] Orchestrator-led sequencing model confirmed
- [x] Hard boundaries documented as non-negotiable constraints
- [x] Architectural assumptions frozen; extension scope no longer changes
