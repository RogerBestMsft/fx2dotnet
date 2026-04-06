---
description: "Run full solution assessment: invoke MCP assessment scenario, classify all projects, compute dependency layers, and audit NuGet package compatibility"
tools:
  - "microsoft.githubcopilot.appmodernization.mcp/get_scenarios"
  - "microsoft.githubcopilot.appmodernization.mcp/get_instructions"
  - "microsoft.githubcopilot.appmodernization.mcp/get_state"
  - "microsoft.githubcopilot.appmodernization.mcp/initialize_scenario"
  - "microsoft.githubcopilot.appmodernization.mcp/start_task"
  - "microsoft.githubcopilot.appmodernization.mcp/complete_task"
  - "microsoft.githubcopilot.appmodernization.mcp/get_projects_in_topological_order"
  - "Swick.Mcp.Fx2dotnet/FindRecommendedPackageUpgrades"
  - "Swick.Mcp.Fx2dotnet/GetMinimalPackageSet"
---

# Assessment Run

Assess a .NET Framework solution end-to-end: invoke the MCP assessment scenario, classify all projects, compute dependency layers, and produce `.fx2dotnet/analysis.md` and `.fx2dotnet/package-updates.md`.

## Constraints

- ONLY gather and analyze information — do NOT make code changes, convert projects, or produce migration plans.
- DO NOT order updates into chunks or create execution sequences — the planner handles that.
- Ground all package compatibility decisions in actual NuGet metadata via MCP tools.

## User Input

$ARGUMENTS

Required: `.sln` or `.slnx` solution path.  
Optional: `targetFramework` (default: `net10.0`), `reuse-existing` flag.

## Steps

### Step 1: Resolve Context

Run `speckit.fx2dotnet-support-core.resolve-solution-context` to normalize the solution path and derive `solutionDir` and `stateRoot`.

### Step 2: Resume Check

Attempt to read `{stateRoot}/analysis.md` using the `read` tool.

If the file exists and contains all expected sections (`## Project Inventory`, `## Dependency Layers`, `## Project Classifications`):
- Report that a prior assessment was found.
- Ask whether to **reuse it** or **re-run the assessment** using `vscode/askQuestions`.
- If reusing, skip to Step 8 and return the existing findings.

If the file does not exist or is incomplete, proceed.

### Step 3: MCP Workflow Initialization

1. Call `get_state()` to check for an existing assessment scenario.
2. If an active scenario exists with assessment tasks, resume from current state.
3. If existing scenarios on disk, present them and ask which to continue.
4. If no scenarios exist, proceed to start a new assessment.

### Step 4: Start Assessment Scenario

1. Call `get_scenarios()` and select the scenario closest to "analysis" or "assessment".
2. **MANDATORY**: Call `get_instructions(kind='scenario', query='{selected_scenario_id}')` before any work.
3. Call `get_instructions(kind='skill', query='scenario-initialization')`.
4. Gather solution path and target framework.
5. Call `initialize_scenario` with the selected scenario.

### Step 5: Execute Assessment Tasks

For each task in `get_state().availableTasks`:
1. Call `start_task(taskId)` and read task content and related skills.
2. Load any relevant skills from `task_related_skills`.
3. Execute the task following loaded instructions.
4. Write findings into `tasks/{taskId}/task.md`.
5. Call `complete_task(taskId, filesModified, executionLogSummary)`.

Stop when all assessment-phase tasks are complete. Do NOT continue into planning or execution tasks.

Handle stale tasks: if `get_state` returns `staleTaskWarnings`, complete or abandon each stale task before starting new ones.

### Step 6: Classify All Projects

After MCP tasks complete, invoke `speckit.fx2dotnet-project-classifier.classify-project` for each project in the solution. Collect classification results.

### Step 7: Compute Dependency Layers

Run `speckit.fx2dotnet-assessment.compute-layers` passing the solution path and project list.

### Step 8: Collect Package Baseline

Run `speckit.fx2dotnet-assessment.collect-package-baseline` to gather compatibility cards via Swick MCP.

### Step 9: Write State Files

**Write `.fx2dotnet/analysis.md`** using the `edit` tool with:
- Project Inventory table (projectId, display name, framework, type, location)
- Framework Inventory summary
- Dependency Layers section
- Project Classifications section (one sub-section per project)

**Write `.fx2dotnet/package-updates.md`** (seed) with:
- Compatibility Findings section
- Any unsupported libraries identified
- Out-of-scope items with post-migration notes

### Step 10: Return Summary

Report:
- Number of projects discovered
- Number of dependency layers
- Number of packages assessed
- Any high-risk compatibility findings
- Path to `analysis.md` for review

## Configuration

Load from `.specify/extensions/fx2dotnet-assessment/fx2dotnet-assessment-config.yml`:

```yaml
discovery:
  scan_depth: unlimited
  include_test_projects: false
advanced:
  mcp_timeout: 30
  use_cache: true
```
