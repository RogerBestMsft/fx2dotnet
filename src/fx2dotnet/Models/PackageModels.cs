internal sealed record PackageVersionInput(string PackageId, string CurrentVersion);

internal sealed record PackageUpgradeRecommendation(
    string PackageId,
    string? CurrentVersion,
    string? MinimumSupportedVersion,
    IReadOnlyList<string> Supports,
    IReadOnlyList<string> SupportFamilies,
    string? Feed,
    bool HasLegacyContentFolder,
    bool HasInstallScript,
    string? Reason);

internal sealed record PackageUpgradeRecommendationResult(
    IReadOnlyList<PackageUpgradeRecommendation> Recommendations,
    string? Reason);

internal sealed record PackageSupportResult(
    string PackageId,
    bool IncludePrerelease,
    string? MinimumVersion,
    IReadOnlyList<string> Supports,
    IReadOnlyList<string> SupportFamilies,
    string? Feed,
    string? Reason);

internal sealed record PackageDependencyDetail(string PackageId, string? VersionRange);

internal sealed record RemovedPackage(string PackageId, string? CurrentVersion, IReadOnlyList<string> ProvidedBy);

internal sealed record MinimalPackageSetResult(IReadOnlyList<PackageVersionInput> Keep, IReadOnlyList<RemovedPackage> Removed, string? Reason);
