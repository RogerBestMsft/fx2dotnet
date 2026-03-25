internal static class DependencyLayerComputer
{
    public static DependencyLayersResult Compute(IReadOnlyList<ProjectDependencyInput> projects)
    {
        // Normalize all paths: lowercase + forward slashes for consistent matching.
        static string Normalize(string path) => path.Replace('\\', '/').ToLowerInvariant();

        // Build the set of known project keys.
        var knownProjects = new HashSet<string>(StringComparer.Ordinal);
        var originalPaths = new Dictionary<string, string>(StringComparer.Ordinal);

        foreach (var p in projects)
        {
            var key = Normalize(p.ProjectPath);
            knownProjects.Add(key);
            // Keep first occurrence as the canonical display path.
            originalPaths.TryAdd(key, p.ProjectPath);
        }

        // Build adjacency: each project maps to its in-scope dependencies.
        var remaining = new Dictionary<string, HashSet<string>>(StringComparer.Ordinal);
        foreach (var p in projects)
        {
            var key = Normalize(p.ProjectPath);
            var deps = new HashSet<string>(StringComparer.Ordinal);
            if (p.Dependencies is not null)
            {
                foreach (var dep in p.Dependencies)
                {
                    var depKey = Normalize(dep);
                    // Only include dependencies that are in the input set.
                    if (knownProjects.Contains(depKey) && depKey != key)
                    {
                        deps.Add(depKey);
                    }
                }
            }

            // If a project appears multiple times, merge dependencies.
            if (remaining.TryGetValue(key, out var existing))
            {
                existing.UnionWith(deps);
            }
            else
            {
                remaining[key] = deps;
            }
        }

        var layers = new List<DependencyLayer>();
        var layerNumber = 0;

        while (remaining.Count > 0)
        {
            // Find all projects with zero remaining dependencies.
            var zeroDeps = remaining
                .Where(kvp => kvp.Value.Count == 0)
                .Select(kvp => kvp.Key)
                .ToList();

            if (zeroDeps.Count == 0)
            {
                break; // Cycle detected — remaining projects form cycles.
            }

            layerNumber++;

            // Sort by original path alphabetically for stable output.
            var layerProjects = zeroDeps
                .Select(k => originalPaths[k])
                .OrderBy(p => p, StringComparer.OrdinalIgnoreCase)
                .ToArray();

            layers.Add(new DependencyLayer(layerNumber, layerProjects));

            // Remove this layer's projects from the graph.
            var zeroDepsSet = new HashSet<string>(zeroDeps, StringComparer.Ordinal);
            foreach (var key in zeroDeps)
            {
                remaining.Remove(key);
            }

            foreach (var deps in remaining.Values)
            {
                deps.ExceptWith(zeroDepsSet);
            }
        }

        // Any remaining projects are in cycles.
        IReadOnlyList<string>? cycles = null;
        if (remaining.Count > 0)
        {
            cycles = remaining.Keys
                .Select(k => originalPaths[k])
                .OrderBy(p => p, StringComparer.OrdinalIgnoreCase)
                .ToArray();
        }

        return new DependencyLayersResult(layers, cycles, null);
    }
}
