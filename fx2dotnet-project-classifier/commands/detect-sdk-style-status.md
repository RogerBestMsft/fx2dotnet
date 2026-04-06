---
description: "Detect whether a project uses SDK-style format and whether SDK-style conversion is applicable"
tools:
  - "read"
---

# Detect SDK-Style Status

Inspect a project file to determine whether it already uses SDK-style format, and if not, whether it is eligible for conversion.

## User Input

$ARGUMENTS

Required: path to a `.csproj`, `.vbproj`, or `.fsproj` file.

## Steps

### Step 1: Read Project File Opening

Use the `read` tool to read the first section of the project file (the root element and first few child elements). Do not load the entire file unless the root is ambiguous.

### Step 2: Evaluate SDK-Style Indicators

**SDK-style** (returns `sdkStyle: true`):
- Root element is `<Project Sdk="...">` — any `Sdk` attribute value qualifies

**Legacy project format** (returns `sdkStyle: false`):
- Root element is `<Project` without an `Sdk` attribute
- May contain `ToolsVersion` attribute
- Typically contains explicit `<Import>` elements for Microsoft targets

### Step 3: Evaluate Conversion Eligibility

If `sdkStyle: true`:
- `conversionEligible: not-applicable` (already converted; no action needed)

If `sdkStyle: false`:
- Check for known blockers that prevent automated SDK conversion:
  - Legacy web application host projects (contain `Microsoft.WebApplication.targets`)
  - Projects with unsupported custom MSBuild extensions
- If no blockers: `conversionEligible: true`
- If blockers found: `conversionEligible: false` with blocker list

### Step 4: Return Result

```markdown
## SDK-Style Status: {projectPath}

- **sdkStyle**: {true | false}
- **conversionEligible**: {true | false | not-applicable}
- **sdkType**: {Microsoft.NET.Sdk | Microsoft.NET.Sdk.Web | legacy | unknown}

### Evidence
- {signal}

### Blockers (if not eligible)
- {blocker description}
```
