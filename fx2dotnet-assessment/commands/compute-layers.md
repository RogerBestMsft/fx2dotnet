---
description: "Compute dependency layers for all projects in topological order using project reference graph"
tools:
  - "microsoft.githubcopilot.appmodernization.mcp/get_projects_in_topological_order"
  - "microsoft.githubcopilot.appmodernization.mcp/get_project_dependencies"
---

# Compute Dependency Layers

Compute topological dependency layers for all projects in the solution. Layer 1 contains leaf projects with no in-solution project references. Each subsequent layer depends only on projects from earlier layers.

## User Input

$ARGUMENTS

Required: solution path. Optional: list of project paths (if already discovered).

## Steps

### Step 1: Get Topological Order

Call `get_projects_in_topological_order` with the solution path. If the tool returns an error or empty list, report the error and stop.

### Step 2: Collect Project Dependencies

Call `get_project_dependencies` for all projects in parallel, passing the solution path and each project path. Collect the returned project-type dependencies for each project.

### Step 3: Build Dependency Map

From the returned dependencies, construct a directed dependency graph:
- Nodes: all projects in the solution (by `projectId`)
- Edges: project A → project B when A has a project reference to B

### Step 4: Compute Layers

Assign each project to a layer using standard topological layering:
1. Layer 1: projects with no in-solution project reference dependencies
2. Layer N: projects whose all dependencies are in layers 1 through N-1

Projects in the same layer are independent and can be processed in any order within that layer (use `projectId` lexical ascending as the stable tie-breaker).

### Step 5: Return Layer Map

Return a structured layer map:

```markdown
## Dependency Layers

### Layer 1 (Leaves — no internal dependencies)
- src/Business/Business.csproj (Business)
- src/Data/Data.csproj (Data)

### Layer 2
- src/Services/Services.csproj (Services) — depends on: Business, Data

### Layer 3
- src/Web/Presentation.csproj (Presentation) — depends on: Services
```

Also return the layer map as a structured list for orchestrator consumption:

```yaml
layers:
  - layer: 1
    projects:
      - projectId: src/Business/Business.csproj
        displayName: Business
  - layer: 2
    projects:
      - projectId: src/Services/Services.csproj
        displayName: Services
        dependsOn:
          - src/Business/Business.csproj
          - src/Data/Data.csproj
```
