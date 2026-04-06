# Manifest Validation Report

Generated: 2026-04-03T22:58:53.6646384Z

## Summary

| Metric | Value |
|---|---:|
| Extension manifests | 11 |
| Provided commands | 32 |
| Hook registrations | 1 |
| Validation status | PASS |

## Extension Matrix

| Extension | Commands | Config Templates | Required Commands | Required Tools | Hooks |
|---|---:|---:|---:|---:|---:|
| fx2dotnet-assessment | 3 | 1 | 3 | 2 | 1 |
| fx2dotnet-build-fix | 3 | 1 | 1 | 0 | 0 |
| fx2dotnet-multitarget | 3 | 1 | 4 | 0 | 0 |
| fx2dotnet-orchestrator | 4 | 1 | 7 | 0 | 0 |
| fx2dotnet-package-compat | 3 | 1 | 4 | 1 | 0 |
| fx2dotnet-planner | 2 | 1 | 2 | 0 | 0 |
| fx2dotnet-project-classifier | 2 | 1 | 0 | 0 | 0 |
| fx2dotnet-sdk-conversion | 3 | 1 | 4 | 2 | 0 |
| fx2dotnet-support-core | 3 | 1 | 0 | 0 | 0 |
| fx2dotnet-web-migration | 3 | 1 | 4 | 0 | 0 |
| fx2dotnet-web-route-inventory | 3 | 1 | 0 | 0 | 0 |

## Dependency Review

- fx2dotnet-assessment: depends on fx2dotnet-project-classifier, fx2dotnet-support-core
- fx2dotnet-build-fix: depends on fx2dotnet-support-core
- fx2dotnet-multitarget: depends on fx2dotnet-build-fix, fx2dotnet-planner
- fx2dotnet-orchestrator: depends on fx2dotnet-assessment, fx2dotnet-multitarget, fx2dotnet-package-compat, fx2dotnet-planner, fx2dotnet-sdk-conversion, fx2dotnet-support-core, fx2dotnet-web-migration
- fx2dotnet-package-compat: depends on fx2dotnet-build-fix, fx2dotnet-support-core
- fx2dotnet-planner: depends on fx2dotnet-assessment, fx2dotnet-support-core
- fx2dotnet-project-classifier: no cross-extension command dependencies
- fx2dotnet-sdk-conversion: depends on fx2dotnet-build-fix, fx2dotnet-support-core
- fx2dotnet-support-core: no cross-extension command dependencies
- fx2dotnet-web-migration: depends on fx2dotnet-build-fix, fx2dotnet-web-route-inventory
- fx2dotnet-web-route-inventory: no cross-extension command dependencies

## Findings

- No manifest, command-file, dependency, or hook coordination issues were detected.
