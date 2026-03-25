internal sealed record ProjectDependencyInput(string ProjectPath, IReadOnlyList<string>? Dependencies);

internal sealed record DependencyLayer(int Layer, IReadOnlyList<string> Projects);

internal sealed record DependencyLayersResult(IReadOnlyList<DependencyLayer> Layers, IReadOnlyList<string>? UnresolvedCycles, string? Error);
