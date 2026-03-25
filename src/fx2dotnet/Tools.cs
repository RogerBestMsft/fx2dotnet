using System.ComponentModel;
using System.Text.Json;
using ModelContextProtocol.Server;

[McpServerToolType]
internal static class Tools
{
    [McpServerTool]
    [Description("Takes a list of NuGet packages with current versions and returns the subset recommended for upgrade to meet minimum .NET Core/.NET or .NET Standard support.")]
    public static async Task<string> FindRecommendedPackageUpgrades(
        [Description("Optional workspace root directory used for default NuGet configuration resolution when nugetConfigPath is not provided.")]
        string? workspaceDirectory,
        [Description("Optional full path to a specific nuget.config file. If null or empty, default NuGet config resolution is used from workspaceDirectory.")]
        string? nugetConfigPath,
        [Description("Packages to evaluate. Each item should include packageId and currentVersion.")]
        IReadOnlyList<PackageVersionInput> packages,
        [Description("When true, prerelease versions are included while searching for the minimum supported version.")]
        bool includePrerelease = false)
    {
        if (packages is null || packages.Count == 0)
        {
            return JsonSerializer.Serialize(new PackageUpgradeRecommendationResult(
                Array.Empty<PackageUpgradeRecommendation>(),
                "packages is required and must contain at least one item."));
        }

        if (packages.Any(p => string.IsNullOrWhiteSpace(p.PackageId)))
        {
            return JsonSerializer.Serialize(new PackageUpgradeRecommendationResult(
                Array.Empty<PackageUpgradeRecommendation>(),
                "Each package item must include a non-empty packageId."));
        }

        var result = await NuGetPackageSupportService.FindRecommendedUpgradesAsync(
            workspaceDirectory,
            nugetConfigPath,
            packages,
            includePrerelease);

        return JsonSerializer.Serialize(result);
    }

    [McpServerTool]
    [Description("Given a set of NuGet packages with versions, returns the minimal subset that must remain as direct PackageReference entries. Packages that are already transitively provided by another package in the set are excluded. Use during SDK-style project conversion to prune unnecessary PackageReference entries.")]
    public static async Task<string> GetMinimalPackageSet(
        [Description("Optional workspace root directory used for default NuGet configuration resolution when nugetConfigPath is not provided.")]
        string? workspaceDirectory,
        [Description("Optional full path to a specific nuget.config file. If null or empty, default NuGet config resolution is used from workspaceDirectory.")]
        string? nugetConfigPath,
        [Description("The set of direct package references to evaluate. Each item should include packageId and currentVersion.")]
        IReadOnlyList<PackageVersionInput> packages)
    {
        if (packages is null || packages.Count == 0)
        {
            return JsonSerializer.Serialize(new MinimalPackageSetResult(
                Array.Empty<PackageVersionInput>(),
                Array.Empty<RemovedPackage>(),
                "packages is required and must contain at least one item."));
        }

        var result = await NuGetPackageSupportService.GetMinimalPackageSetAsync(
            workspaceDirectory,
            nugetConfigPath,
            packages);

        return JsonSerializer.Serialize(result);
    }

    [McpServerTool]
    [Description("Computes dependency layers for a set of projects using iterative graph reduction. Layer 1 contains projects with no in-scope dependencies; each subsequent layer depends only on earlier layers. Returns layers as JSON. The caller is responsible for gathering the project dependency graph (e.g. via get_projects_in_topological_order or project file parsing) before invoking this tool.")]
    public static string ComputeDependencyLayers(
        [Description("Projects and their in-scope dependencies. Each entry has a projectPath and a list of dependency project paths that are also in this input set.")]
        IReadOnlyList<ProjectDependencyInput> projects)
    {
        if (projects is null || projects.Count == 0)
        {
            return JsonSerializer.Serialize(new DependencyLayersResult(
                Array.Empty<DependencyLayer>(), null, "projects is required and must contain at least one item."));
        }

        if (projects.Any(p => string.IsNullOrWhiteSpace(p.ProjectPath)))
        {
            return JsonSerializer.Serialize(new DependencyLayersResult(
                Array.Empty<DependencyLayer>(), null, "Each project entry must include a non-empty projectPath."));
        }

        var result = DependencyLayerComputer.Compute(projects);
        return JsonSerializer.Serialize(result);
    }
}
