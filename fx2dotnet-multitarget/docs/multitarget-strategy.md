# Multitarget Strategy

Strategy and rules for the fx2dotnet Multitarget phase.

## Goal

Add modern target frameworks incrementally while preserving the original .NET Framework target and fixing API gaps one logical change at a time.

## Rules

1. Preserve the existing framework target exactly.
2. Add requested frameworks via `TargetFrameworks` rather than replacing the original target.
3. Fix API gaps independently and checkpoint after each fix.
4. Never add new packages without user approval.
5. Apply domain policies when encountering `System.Web`, EF6, or Windows Service types.

## Domain Policies

### System.Web Adapters

When build errors involve `System.Web` types:
- Use `Microsoft.AspNetCore.SystemWebAdapters`
- Do not rewrite to native ASP.NET Core types in this phase
- See `docs/systemweb-adapters-note.md`

### EF6

Retain EF6 as-is. Do not migrate to EF Core.

### Windows Service

Migrate to `BackgroundService` + `Microsoft.Extensions.Hosting.WindowsServices` when required.
