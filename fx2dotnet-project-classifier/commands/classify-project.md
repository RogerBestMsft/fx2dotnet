---
description: "Classify a .NET project as web host, web library, Windows Service, console, or library and return classification with evidence"
tools:
  - "read"
  - "search"
---

# Classify Project

Read a project file and classify its type, returning a structured classification result with evidence. This command is called by the assessment extension for each project in the solution.

## When to Apply

Apply this command when:
- The solution contains projects of unknown type
- Assessment needs project classifications before computing dependency layers
- A `windows-service` classification is required (look for `ServiceBase`, `ServiceController`, `TopShelf`)

## Prerequisites

- Project file path (`.csproj`, `.vbproj`, or `.fsproj`) must be provided.

## User Input

$ARGUMENTS

Required: path to a `.csproj`, `.vbproj`, or `.fsproj` file.

## Steps

### Step 1: Read Project File

Use the `read` tool to read the project file. If the read fails, stop and report the error.

Do not read more of the file than needed. Focus on:
- The root `<Project>` element and its `Sdk` attribute
- `<OutputType>` element
- `<PackageReference>` elements
- `<ProjectReference>` elements
- `<Reference>` elements for framework assemblies

Also use the `search` tool to check for host-level artifacts in the project folder:
- `Global.asax`, `web.config`, `RouteConfig`, `WebApiConfig`
- `Program.cs` with hosting bootstrap patterns
- `ServiceInstaller`, `ServiceBase` subclasses

### Step 2: Detect SDK-Style Format

Inspect the root `<Project>` element:
- **SDK-style**: `<Project Sdk="...">` attribute present (e.g., `Microsoft.NET.Sdk`, `Microsoft.NET.Sdk.Web`)
- **Legacy**: root element has no `Sdk` attribute

### Step 3: Classify Project Type

Evaluate these signals in priority order:

**Web Host** (all of the following):
- Uses `Microsoft.NET.Sdk.Web` SDK, OR legacy web-host project imports (`Microsoft.WebApplication.targets`)
- Contains host artifacts: `Global.asax`, `web.config`, `RouteConfig`, `WebApiConfig`, OWIN `Startup`, or `.aspx` pages
- OutputType is `Exe` or absent (web app default)

**Web Library** (references web frameworks but is NOT a host):
- References `System.Web`, `Microsoft.AspNet.WebApi`, `Microsoft.AspNet.Mvc`, or OWIN packages
- OutputType is `Library`
- No host artifacts detected

**Windows Service** (any of the following):
- References `System.ServiceProcess` and subclasses `ServiceBase`
- References `TopShelf`
- Contains `ServiceInstaller` class

**Console Application**:
- OutputType is `Exe` and no web-host indicators

**Class Library** (default):
- OutputType is `Library` and no web or service indicators

If signals are ambiguous, classify as `uncertain` and include the conflicting signals in the explanation.

### Step 4: Return Classification

Return a structured classification result:

```markdown
## Classification: {projectPath}

- **type**: {web-host | web-library | windows-service | console | library | uncertain}
- **sdkStyle**: {true | false}
- **sdkConversionEligible**: {true | false | not-applicable}
- **confidence**: {high | medium | low}

### Evidence
- {signal 1}
- {signal 2}

### Actions
- {needs-sdk-conversion | skip-already-sdk | web-app-host | windows-service | uncertain-web}
```

If `confident` is `low`, emit an uncertainty marker:

```
<!-- uncertainty: type | reason: {explanation} | action: needs-user-confirmation -->
```

## Classification Rules

| Signal | Inferred Type |
|---|---|
| `Sdk="Microsoft.NET.Sdk.Web"` | web-host candidate |
| `Microsoft.WebApplication.targets` import | web-host (legacy format) |
| `Global.asax` or `web.config` in project folder | web-host supporting evidence |
| `OutputType=Library` + web package refs | web-library |
| `ServiceBase` subclass | windows-service |
| `TopShelf` package reference | windows-service |
| `OutputType=Exe` + no web indicators | console |
| `OutputType=Library` + no web/service indicators | library |
