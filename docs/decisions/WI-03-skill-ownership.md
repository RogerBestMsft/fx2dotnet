# WI-03: Shared Skill Ownership Decision Record

**Status**: Done  
**Date**: April 3, 2026  
**Depends On**: WI-01, WI-02  

---

## Skill Inventory and Classification

| Skill | Current Location | Classification | Owner Extension | Consumers | Disposition |
|---|---|---|---|---|---|
| `ef6-migration-policy` | `skills/ef6-migration-policy/SKILL.md` | Shared operational policy | `fx2dotnet-planner` (doc anchor) | `fx2dotnet-planner`, `fx2dotnet-package-compat`, `fx2dotnet-multitarget` | Move into `fx2dotnet-planner/docs/ef6-migration-policy.md`; symlink reference in consumer docs |
| `systemweb-adapters` | `skills/systemweb-adapters/SKILL.md` + `references/` | Phase-specific policy | `fx2dotnet-web-migration` | `fx2dotnet-multitarget` (cross-reference only) | Move SKILL.md into `fx2dotnet-web-migration/docs/systemweb-adapters.md`; move `references/` sub-docs into `fx2dotnet-web-migration/docs/references/` |
| `windows-service-migration` | `skills/windows-service-migration/SKILL.md` | Shared operational policy | `fx2dotnet-project-classifier` (discovery) + `fx2dotnet-planner` (execution constraint) | `fx2dotnet-multitarget` (applies constraint) | Copy into both `fx2dotnet-project-classifier/docs/` and `fx2dotnet-planner/docs/`; `planner` is canonical owner |
| `owin-identity` | `skills/owin-identity/SKILL.md` | Phase-specific policy | `fx2dotnet-web-migration` | `fx2dotnet-planner` (cross-reference) | Move into `fx2dotnet-web-migration/docs/owin-identity.md`; reference note in planner |
| `build-error-triage` | `skills/build-error-triage/` (placeholder) | Deferred | Not assigned | — | Retain as placeholder; not in active scope for current release |
| `package-compatibility-policy` | `skills/package-compatibility-policy/` (placeholder) | Deferred | Not assigned | — | Retain as placeholder; not in active scope for current release |
| `phase-gate-state-contract` | `skills/phase-gate-state-contract/` (placeholder) | Deferred | Not assigned | — | Retain as placeholder; not in active scope for current release |
| `project-classification` | `skills/project-classification/` (placeholder) | Deferred | Not assigned | — | Retain as placeholder; not in active scope for current release |
| `sdk-conversion-strategy` | `skills/sdk-conversion-strategy/` (placeholder) | Deferred | Not assigned | — | Retain as placeholder; not in active scope for current release |

---

## Ownership Rules

### Rule 1 — Single canonical owner
Each active skill has exactly one owning extension. The owner's `docs/` folder is the canonical location.

### Rule 2 — Consumer copy, not shared path
Consumer extensions copy the skill content into their own `docs/` directory. They do not reference the shared `skills/` source path at runtime.

### Rule 3 — Discovery trigger phrases
Each skill is invoked by keyword phrases in command documentation. Trigger phrases must appear in the `## When to Apply` section of every command that uses the skill.

---

## Skill → Extension Mapping (Canonical)

### ef6-migration-policy

- **Canonical owner**: `fx2dotnet-planner`
- **Canonical file**: `fx2dotnet-planner/docs/ef6-migration-policy.md`
- **Consumer copies**:
  - `fx2dotnet-package-compat/docs/ef6-migration-policy.md`
  - `fx2dotnet-multitarget/docs/ef6-migration-policy.md`
- **Trigger phrases**: "EF6", "EntityFramework", "Entity Framework 6", "retain EF6", "do not upgrade to EF Core"
- **Precedence**: EF6 retention always wins over EF Core upgrade. No extension may suggest EF Core as a replacement without explicit user approval.

### systemweb-adapters

- **Canonical owner**: `fx2dotnet-web-migration`
- **Canonical files**:
  - `fx2dotnet-web-migration/docs/systemweb-adapters.md`
  - `fx2dotnet-web-migration/docs/references/behavioral-differences.md`
  - `fx2dotnet-web-migration/docs/references/migrating-handlers.md`
  - `fx2dotnet-web-migration/docs/references/migrating-modules.md`
  - `fx2dotnet-web-migration/docs/references/property-translations.md`
- **Consumer copies**: `fx2dotnet-multitarget/docs/systemweb-adapters-note.md` (summary only, not full doc)
- **Trigger phrases**: "System.Web", "HttpContext", "HttpRequest", "HttpResponse", "IHttpModule", "IHttpHandler", "HttpApplication", "SystemWebAdapters", "side-by-side web migration"
- **Precedence**: System.Web types encountered during multitarget must use `Microsoft.AspNetCore.SystemWebAdapters` package — never rewrite to native ASP.NET Core types without explicit web-migration phase approval.

### windows-service-migration

- **Canonical owner**: `fx2dotnet-planner`
- **Canonical file**: `fx2dotnet-planner/docs/windows-service-migration.md`
- **Consumer copies**:
  - `fx2dotnet-project-classifier/docs/windows-service-migration.md`
  - `fx2dotnet-multitarget/docs/windows-service-migration.md`
- **Trigger phrases**: "Windows Service", "ServiceBase", "ServiceController", "ServiceInstaller", "TopShelf", "windows-service"
- **Precedence**: Windows Service projects get both `needs-sdk-conversion` (if legacy) and `windows-service` action tags in the plan. The `BackgroundService` + `Microsoft.Extensions.Hosting.WindowsServices` replacement is the canonical migration path.

### owin-identity

- **Canonical owner**: `fx2dotnet-web-migration`
- **Canonical file**: `fx2dotnet-web-migration/docs/owin-identity.md`
- **Consumer copies**: None required (planner adds a note to check for OWIN in risk summary)
- **Trigger phrases**: "OWIN", "Katana", "Microsoft.Owin", "IAppBuilder", "OwinContext", "identity middleware"
- **Precedence**: OWIN identity dependencies require explicit user decision on replacement strategy during web migration planning; do not auto-substitute ASP.NET Core Identity without approval.

---

## Conflict Resolution

| Conflict | Resolution |
|---|---|
| EF6 retention vs. EF Core suggestion | EF6 retention always wins. Owner (`planner`) policy takes precedence over any suggestion in consumer extensions. |
| System.Web adapter vs. native Core rewrite | Adapter approach wins at multitarget phase. Native rewrite is only permitted during the explicit web-migration phase with user approval. |
| Windows Service vs. cross-platform hosting | Windows Service migration uses `BackgroundService` on Windows. Cross-platform (`Systemd`) hosting is out of scope for this migration; no Systemd packages are added. |
| OWIN identity vs. ASP.NET Core Identity | No auto-replacement. Planner flags OWIN as open question requiring user decision before web migration proceeds. |

---

## Reference-Only Assets (Not Executable Skills)

These files are documentation only and must not be invoked as skills:

- `skills/systemweb-adapters/references/behavioral-differences.md` — reference material, not a workflow constraint
- `skills/systemweb-adapters/references/property-translations.md` — reference table, not a workflow constraint

These are retained in `skills/` for source history but copied into `fx2dotnet-web-migration/docs/references/` as the runtime-serving location.

---

## Deferred Skills (Not in Active Scope)

The following placeholder folders exist but have no `SKILL.md` content and are not assigned to any extension for the current release:

- `build-error-triage/`
- `package-compatibility-policy/`
- `phase-gate-state-contract/`
- `project-classification/`
- `sdk-conversion-strategy/`

These remain as placeholder directories. They must not be referenced by any extension manifest or command.

---

## Exit Criteria — Satisfied

- [x] Shared vs. per-extension policy ownership documented and approved
- [x] No skill is left ambiguous across multiple extensions
- [x] Every in-scope skill has explicit triggers and precedence behavior
- [x] WI-04 through WI-14 can consume this matrix without re-deciding skill placement
