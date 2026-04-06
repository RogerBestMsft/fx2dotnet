# Shared Conventions

Conventions applied consistently across all fx2dotnet extensions.

## Path Normalization

- All paths stored in state files use forward slashes (`/`) as separators regardless of OS.
- `solutionDir` is always the **parent directory** of the `.sln` or `.slnx` file.
- `stateRoot` is always `{solutionDir}/.fx2dotnet/`.
- `projectId` is always the normalized relative path from `solutionDir` to the `.csproj` file using forward slashes.

## Command Naming

All commands follow: `speckit.fx2dotnet-{extension-id}.{command-name}`

No command may shadow a core spec-kit command or another fx2dotnet command.

## File Read/Write Policy

- **Check existence**: Use the `read` tool. If the read fails, the file does not exist.
- **Create/update**: Use the `edit` tool. Never use shell commands for state file operations.
- **Atomic sections**: Each extension writes only its own owned section. Existing sections from other owners are preserved.

## Subagent Policy for CLI Commands

All `dotnet build`, `dotnet restore`, and similar CLI commands MUST be run via a **subagent** — never directly in the terminal from an extension command. Pass the command to a subagent and instruct it to return: exit code, error/warning counts, and the full diagnostic list.

## Uncertainty and Confirmation

When a command cannot produce a confident output, it must:
1. Emit an `<!-- uncertainty: ... -->` marker in the relevant state section.
2. Include a summary in its output explaining what is uncertain and why.
3. Never proceed past a gate based on uncertain data without user confirmation.

## Resumability

Every stateful command must begin with a **resume check**:
1. Read the relevant state section.
2. If a prior run is found and appears complete, offer to reuse it or re-run.
3. If a prior run is found and appears incomplete, offer to resume or start fresh.
4. If no prior state is found, proceed with fresh initialization.

## Per-Project Identity

- `projectId` = normalized relative `.csproj` path from solution root (e.g., `src/Web/Web.csproj`).
- `displayName` = friendly project name for human display only.
- All state joins, matrix rows, and orchestrator checkpoints use `projectId`.
- When two projects share the same display-name stem, append a short deterministic hash to the state file name.

## Commit Granularity

Each migration step produces the smallest useful diff. Extensions offer a **Commit Changes** handoff after significant file edits. Batch identical fixes (e.g., adding the same `using` across files) as one logical change.
