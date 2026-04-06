# EF6 Migration Policy

**Applies to**: `fx2dotnet-planner`, `fx2dotnet-package-compat`, `fx2dotnet-multitarget`  
**Trigger phrases**: "EF6", "EntityFramework", "Entity Framework 6", "retain EF6", "do not upgrade to EF Core"

## Policy: Retain EF6

Entity Framework 6 is supported on modern .NET (net8.0+). When EF6 is present in a solution, the fx2dotnet migration suite **retains it**. EF Core migration is a distinct, post-modernization activity outside the scope of this workflow.

## Rules

1. **Never place EF6 packages in the upgrade chunk queue.** The `EntityFramework` package at version 6.x is not treated as requiring an upgrade.
2. **Never suggest EF Core as a replacement** for EF6 during assessment, planning, package-compat, or multitarget phases.
3. **Mark EF6 as `retain-as-is`** in the package compatibility findings with the note: "EF6 is supported on modern .NET. Retain for now."
4. **Do not add `Microsoft.EntityFrameworkCore` packages** unless the user explicitly approves it as an out-of-scope activity.
5. When multitarget build errors involve EF6 API surface, investigate whether the error is a compile error caused by a different missing dependency before touching EF6 code.

## Detection

EF6 is detected when:
- `<PackageReference Include="EntityFramework" Version="6.*" />` or similar appears in any project file
- `using System.Data.Entity;` appears in source files

## Compliance

Any extension that surfaces package update recommendations must check for EF6 and exclude it from automated changes. User must explicitly opt into EF Core migration outside this workflow.
