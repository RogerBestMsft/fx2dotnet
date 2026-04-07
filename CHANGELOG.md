# Changelog

All notable changes to the fx-to-dotnet Spec Kit extension family will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-04-07

### Fixed

- Corrected PowerShell deploy script string interpolation so deployment works when run from another directory
- Declared command dependencies in Spec Kit command frontmatter so orchestrated phase commands are available at runtime

## [0.1.0] - 2026-04-06

### Added

- Initial release of the fx-to-dotnet Spec Kit extension family (11 extensions)
- Orchestrator extension coordinating 7-phase migration workflow
- Assessment, planning, SDK conversion, package compat, multitarget, and web migration phases
- Build fix extension callable from any phase
- Project type detection and route inventory extensions
- Policy extension with EF6 retention, OWIN identity, System.Web adapters, and Windows Service migration policies
- CI/CD workflows for validation and release
- Packaging, version bump, cross-reference audit, and catalog generation scripts
