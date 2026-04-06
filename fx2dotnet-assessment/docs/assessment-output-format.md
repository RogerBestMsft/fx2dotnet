# Assessment Output Format

This document defines the expected structure and content of state files produced by the `fx2dotnet-assessment` extension.

## analysis.md

**Location**: `{solutionDir}/.fx2dotnet/analysis.md`  
**Owner**: `fx2dotnet-assessment`  
**Consumers**: `fx2dotnet-planner`, `fx2dotnet-sdk-conversion`, `fx2dotnet-package-compat`, `fx2dotnet-multitarget`, `fx2dotnet-web-migration`

### Required Sections

#### 1. File Header

```markdown
# Assessment Report

**Date**: {ISO-8601 date}
**Solution**: {relative path to solution file}
**Assessed Projects**: {count}
**Target Framework**: {e.g. net10.0}
```

#### 2. Project Inventory Table

```markdown
## Project Inventory

| projectId | Project | Framework | Type | Location |
|-----------|---------|-----------|------|----------|
| src/Business/Business.csproj | Business | .NET Framework 4.8 | Class Library | src/Business/ |
```

- `projectId`: normalized relative path from solution root, forward slashes
- `Type`: Class Library | Web Application | Console Application | Windows Service

#### 3. Framework Inventory

```markdown
## Framework Inventory

- **.NET Framework 4.8**: {count} projects
- **.NET Standard 2.0**: {count} projects
```

#### 4. Dependency Layers

```markdown
## Dependency Layers

### Layer 1 (Leaves — no internal dependencies)
- {projectId} ({displayName})

### Layer 2
- {projectId} ({displayName}) — depends on: {displayName1}, {displayName2}
```

#### 5. Project Classifications

```markdown
## Project Classifications

### {displayName}
- **projectId**: {projectId}
- **Type**: {Class Library | Web Application | Console Application | Windows Service}
- **SDK-style Status**: {Candidate | Already SDK-style | Not applicable}
- **SDK Conversion Action**: {needs-sdk-conversion | skip-already-sdk | web-app-host | uncertain-web | windows-service}
- **Confidence**: {high | medium | low}
- **Evidence**: {brief evidence list}
```

## package-updates.md (Seed)

**Location**: `{solutionDir}/.fx2dotnet/package-updates.md`  
**Seeded by**: `fx2dotnet-assessment`  
**Execution state added by**: `fx2dotnet-package-compat`

### Required Sections (Seed)

```markdown
# Package Updates

**Solution**: {path}
**Target Framework**: {tfm}
**Assessment Date**: {date}

## Compatibility Findings

**Total Packages Assessed**: {count}
**Low Risk**: {count}
**Medium Risk**: {count}
**High Risk**: {count}
**Blocking**: {count}

## Compatibility Cards

### {PackageId} {Version}
- **Target Support**: {supported | not-supported | unknown}
- **Minimum Compatible Version**: {version | N/A}
- **Upgrade Path**: {version | none | replace-with:{alternative}}
- **Legacy Content Flag**: {true | false}
- **Risk Level**: {low | medium | high | blocking}

## Unsupported Libraries

| Package | Current Version | Reason | Recommended Action |
|---------|----------------|---------|-------------------|

## Out-of-Scope Items

| Package | Reason Deferred | Post-Migration Action |
|---------|----------------|----------------------|
```
