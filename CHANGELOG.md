# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-03-31

### Added

- Added `speckit.fx2dotnet-migration.orchestrate`: Orchestrates end-to-end modernization flow: run assessment, create migration plan, process projects in topological order for SDK-style conversion (excluding web apps), then run package compatibility migration, project-by-project multitarget migration in topological order, and ASP.NET Framework to ASP.NET Core web migration.
- Added `speckit.fx2dotnet-migration.assessment`: Gathers information about a .NET solution for migration to .NET 10. Identifies frameworks, dependencies, routes, and blockers. Classifies each project (SDK-style vs legacy, web host vs library). Resolves NuGet feeds, audits package compatibility, and produces compatibility cards. Returns the assessment report path, topological project order, project classifications, and package compatibility findings.
- Added `speckit.fx2dotnet-migration.planning`: Synthesizes assessment findings into an actionable migration plan. Consumes project classifications, orders package updates into minimal-risk chunks, and produces a phased execution plan for SDK conversion, multitargeting, and ASP.NET Core migration.
- Added `speckit.fx2dotnet-migration.sdk-conversion`: Convert a legacy project file to SDK-style format using the convert_project_to_sdk_style tool, then invoke Build Fix to resolve any compilation errors until the project builds successfully.
- Added `speckit.fx2dotnet-migration.package-compat`: Applies a pre-built package compatibility plan to a .NET solution. Executes chunked package version updates and invokes Build Fix after each chunk. Requires the chunked update plan from the Migration Planner.
- Added `speckit.fx2dotnet-migration.multitarget`: Use when multitargeting a .NET project to add multiple target frameworks. Identifies pre-migration API issues, applies minimal fixes with checkpoints, updates TargetFramework to TargetFrameworks, and verifies by invoking Build Fix.
- Added `speckit.fx2dotnet-migration.web-migration`: Plan and execute a web-project-first migration from ASP.NET (.NET Framework) to ASP.NET Core by inventorying endpoints, scaffolding a new ASP.NET Core host, and porting artifacts incrementally. Use when: migrate a System.Web Web API or MVC app to ASP.NET Core, replace a legacy web host with a new ASP.NET Core project, inventory endpoints before migration, move an old web application onto libraries that already work on ASP.NET Core.
