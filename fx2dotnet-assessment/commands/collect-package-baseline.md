---
description: "Collect NuGet package baseline and compatibility cards for all projects using Swick MCP"
tools:
  - "Swick.Mcp.Fx2dotnet/FindRecommendedPackageUpgrades"
  - "Swick.Mcp.Fx2dotnet/GetMinimalPackageSet"
---

# Collect Package Baseline

Gather the NuGet package baseline for all projects in the solution using the Swick MCP tools. Produce compatibility cards (current version, target support, minimum compatible version, legacy flags) for every package.

## User Input

$ARGUMENTS

Required: solution path, target framework (default: `net10.0`).

## Steps

### Step 1: Collect All Package References

For each project in the solution, identify all NuGet package references. Collect: package ID, current version, and which project(s) reference it.

Use the `read` tool to inspect project files or `Directory.Packages.props` when central package management is in use.

### Step 2: Call FindRecommendedPackageUpgrades

Call `Swick.Mcp.Fx2dotnet/FindRecommendedPackageUpgrades` with the solution path and target framework. Collect the returned upgrade recommendations.

### Step 3: Build Compatibility Cards

For each package identified, produce a compatibility card:

```markdown
### {PackageId} {CurrentVersion}

- **Target Support**: {supported | not-supported | unknown}
- **Minimum Compatible Version**: {version | N/A}
- **Upgrade Path**: {version to upgrade to | none | replace-with:{alternative}}
- **Legacy Content Flag**: {true | false} — install scripts or content that may not work
- **Risk Level**: {low | medium | high | blocking}
```

Risk level rules:
- `blocking` — no compatible version exists for the target framework
- `high` — compatible version exists but requires breaking API changes or behavior differences
- `medium` — compatible version exists; possible minor API changes
- `low` — compatible version exists; straightforward upgrade

### Step 4: Identify Unsupported Libraries

For packages with `Target Support: not-supported` and no `upgrade-path`:
- Record them in an **Unsupported Libraries** list.
- Each entry must include: package ID, current version, reason, and recommended fallback or manual action.

### Step 5: Identify Out-of-Scope Items

For packages that are not blocking migration but will require post-migration attention:
- Record them in an **Out-of-Scope Items** list.
- Each entry includes: package ID, reason it's deferred, and recommended post-migration action.

### Step 6: Write Package Baseline

Append the package baseline to `.fx2dotnet/package-updates.md` under `## Compatibility Findings`:

```markdown
## Compatibility Findings

**Target Framework**: net10.0
**Total Packages Assessed**: {count}
**Low Risk**: {count}
**Medium Risk**: {count}
**High Risk**: {count}
**Blocking**: {count}

## Compatibility Cards
{cards}

## Unsupported Libraries
{unsupported}

## Out-of-Scope Items
{out-of-scope}
```
