# fx2dotnet Migration Extension Plan

## Purpose

This document defines the plan for adding a spec-kit community extension to this repository without changing or removing any existing code, agent definitions, skills, MCP configuration, or plugin behavior.

The extension will repackage the repository's existing .NET Framework to modern .NET migration guidance into spec-kit commands that can be installed locally with `specify extension add --dev` and prepared for later community publication.

## Goals

The planned extension will:

1. Introduce a new extension manifest and packaging assets inside this repository.
2. Expose one primary orchestration command for the full migration flow.
3. Expose phase commands that mirror the existing migration agents.
4. Register those commands directly from the existing files under `agents/` instead of duplicating command content into a separate `commands/` folder.
5. Include packaging assets needed for local installation and future publication.

## Non-Goals

This plan does not include:

1. Modifying existing files such as `README.md`, `plugin.json`, `.mcp.json`, files under `agents/`, files under `skills/`, or files under `src/`.
2. Changing how the existing fx2dotnet plugin works.
3. Editing generated spec-kit outputs.
4. Submitting anything upstream to the spec-kit community catalog as part of this repository change.
5. Adding new migration logic beyond what is already described in this repository.

## Extension Identity

- Extension ID: `fx2dotnet-migration`
- Package intent: standalone spec-kit community extension
- Command namespace: `speckit.fx2dotnet-migration.*`

The package should be created as an add-only set of files that remains isolated from the existing plugin implementation.

## Proposed Package Shape

The extension should be added without introducing a separate `commands/` folder. Instead, the extension manifest should register command entries that point directly at the existing markdown files in `agents/`.

Example structure:

```text
<repo-root>/
├── extension.yml
├── agents/
│   ├── dotnet-fx-to-modern-dotnet.md
│   ├── assessment.agent.md
│   ├── migration-planner.agent.md
│   ├── sdk-project-conversion.agent.md
│   ├── package-compat-core.agent.md
│   ├── multitarget.agent.md
│   └── aspnet-framework-to-aspnetcore-web-migration.agent.md
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .extensionignore
```

This implies the extension manifest must live at the repository root, or at another location where the `agents/` paths remain inside the extension root and do not require `../` traversal.

## Planned Command Surface

### Primary Command

- `speckit.fx2dotnet-migration.orchestrate`

Purpose:
Provide the end-to-end migration entry point that reflects the current repo's orchestration flow:

1. Assessment
2. Planning
3. SDK-style conversion
4. Package compatibility migration
5. Multitarget migration
6. ASP.NET Framework to ASP.NET Core web migration
7. Deferred follow-up work

### Phase Commands

- `speckit.fx2dotnet-migration.assessment`
- `speckit.fx2dotnet-migration.planning`
- `speckit.fx2dotnet-migration.sdk-conversion`
- `speckit.fx2dotnet-migration.package-compat`
- `speckit.fx2dotnet-migration.multitarget`
- `speckit.fx2dotnet-migration.web-migration`

Each command should mirror the intent and constraints of the existing agent that already serves that phase, with the manifest pointing directly to that existing agent file.

## Source Mapping

The extension should be written from the existing repository content, not from new migration instructions or duplicated command markdown.

### Core Sources

- `README.md`
  - Reuse prerequisites, overview text, phase summaries, and migration flow terminology.
- `plugin.json`
  - Reuse product naming and relationship to the current plugin.
- `.mcp.json`
  - Reuse prerequisite information for MCP-backed tooling.
- `.github/copilot-instructions.md`
  - Reuse architecture overview (orchestrator, phase agents, skills, MCP server roles),
    agent file conventions (YAML frontmatter fields, handoffs, state-file path),
    and code-change constraints (smallest-possible diff, no unconfirmed NuGet adds).

### Command Sources

- `agents/dotnet-fx-to-modern-dotnet.md`
  - Source for the orchestration command, phase ordering, checkpoint behavior, and `.fx2dotnet/` state-file conventions.
- `agents/assessment.agent.md`
  - Source for the Assessment phase command.
- `agents/migration-planner.agent.md`
  - Source for the Planning phase command.
- `agents/sdk-project-conversion.agent.md`
  - Source for the SDK Conversion phase command.
- `agents/package-compat-core.agent.md`
  - Source for the Package Compatibility phase command.
- `agents/multitarget.agent.md`
  - Source for the Multitarget phase command.
- `agents/aspnet-framework-to-aspnetcore-web-migration.agent.md`
  - Source for the Web Migration phase command.
- `agents/build-fix.agent.md`
  - Supporting source for validation and checkpoint language used across multiple commands.

### Policy Sources

- `skills/ef6-migration-policy/SKILL.md`
  - Reuse EF6 retention and deferred-upgrade guidance.
- `skills/systemweb-adapters/SKILL.md`
  - Reuse System.Web adapter guidance.
- `skills/windows-service-migration/SKILL.md`
  - Reuse Windows Service migration guidance.
- `skills/owin-identity/SKILL.md`
  - Reuse identity-related migration guidance where applicable.

The skills remain source material only. The plan does not move, rename, or alter them.

## Manifest Plan

The extension manifest should follow the spec-kit extension guide and include:

1. `schema_version: "1.0"`
2. Extension metadata with the selected ID and semantic version.
3. A `requires` block with a compatible `speckit_version` range.
4. A `provides.commands` list for the orchestration command and all phase commands.
5. Command file paths that point directly to the existing files in `agents/`.

Hooks and config should be omitted unless implementation reveals a concrete need. The requested command surface does not require them.

Because spec-kit command file paths must remain relative to the extension root, the manifest placement must be chosen so the `agents/` directory is inside that root. The plan should not rely on paths that escape the extension root.

## Documentation Plan

The packaging `README.md` should document:

1. What the extension is.
2. How it relates to the existing fx2dotnet plugin.
3. Required environment prerequisites.
4. Local installation using `specify extension add --dev`.
5. Available commands.
6. Expected inputs such as solution path and target framework.
7. The non-invasive design of the package.

The packaging `CHANGELOG.md` should start at the initial release version.

The packaging `LICENSE` should be chosen explicitly during implementation rather than inferred.

The `.extensionignore` file should exclude development-only artifacts so installation copies only shippable files.

## Implementation Sequence

1. Choose the extension root location so the existing `agents/` directory is inside the extension root.
2. Add `extension.yml` with metadata and command registrations that reference the existing files in `agents/`.
3. Verify that the existing orchestrator and phase agent files are suitable to serve as spec-kit command sources without duplication.
4. Add packaging documentation files.
5. Add `.extensionignore`.
6. Validate package structure and command naming.
7. Test local installation and command registration.

## Validation Plan

The implementation should verify the following:

1. The extension ID matches spec-kit validation rules.
2. Each command name follows the `speckit.{ext-id}.{command}` pattern.
3. Every manifest command path exists under `agents/` and is relative to the extension root.
4. The package installs locally with `specify extension add --dev`.
5. The package appears in `specify extension list`.
6. The orchestration command and at least one phase command register successfully in the target AI environment.
7. The package excludes non-shipping files through `.extensionignore`.

## Constraints

The implementation must preserve these repository constraints:

1. Add-only change set.
2. No edits to tracked plugin behavior.
3. No removal or replacement of current agent instructions.
4. No modification of existing skill policies.
5. No source-code or MCP-server changes.

## Risks and Mitigations

### Risk: Agent content may assume tool-specific execution details

Mitigation:
Preserve the existing workflow and constraints in command content, and document any environment-specific differences in the extension README instead of altering the original agent files.

### Risk: Existing agent files may not map cleanly to spec-kit command registration

Mitigation:
Validate early that spec-kit accepts the existing agent markdown files as command file targets. If any file format mismatch is discovered, stop and reassess before introducing duplication.

### Risk: Packaging location may affect future extraction or publication

Mitigation:
Place the manifest where it can reference `agents/` directly without escaping the extension root, and keep added packaging assets minimal so later extraction remains straightforward.

### Risk: Community catalog work could be conflated with the extension package work

Mitigation:
Treat community catalog submission as a follow-up step after local validation. Do not modify upstream catalog references in this repository change.

## Completion Criteria

This plan is considered implemented when:

1. A new standalone extension package exists in this repository.
2. The package contains a valid manifest, publishing-ready assets, and command registrations that point to the existing files in `agents/`.
3. The command set includes one orchestration command and the agreed phase commands.
4. The package can be installed locally for development.
5. No existing repository files were modified to make the extension work.

## Next Step

Implement the extension packaging described here so the manifest registers commands directly from the existing `agents/` files, while keeping all current code and documentation intact.