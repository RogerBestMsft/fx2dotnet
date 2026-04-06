param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifestDirectory = Join-Path $RepoRoot "packaging/artifact-manifests"
$manifestPaths = @(Get-ChildItem -Path $manifestDirectory -Filter "*.json" | Sort-Object Name)

if ($manifestPaths.Count -eq 0) {
    throw "No artifact manifests were found in $manifestDirectory."
}

foreach ($manifestPath in $manifestPaths) {
    $artifactManifest = Get-Content -Path $manifestPath.FullName -Raw | ConvertFrom-Json
    $extensionRoot = Join-Path $RepoRoot $artifactManifest.extensionId

    foreach ($runtimeAsset in @($artifactManifest.runtimeAssets)) {
        $sourcePath = Join-Path $RepoRoot (($runtimeAsset.sourcePath -replace "/", "\") -replace "\\(Debug|Release)$", "\$Configuration")
        $targetPath = Join-Path $extensionRoot (($runtimeAsset.targetPath -replace "/", "\") -replace "\\(Debug|Release)$", "\$Configuration")

        if (-not (Test-Path $sourcePath)) {
            if ($runtimeAsset.required) {
                throw "Required runtime asset source path not found: $sourcePath"
            }

            continue
        }

        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path (Join-Path $sourcePath "*") -Destination $targetPath -Recurse -Force
        Write-Host "Staged runtime assets for $($artifactManifest.extensionId) to $targetPath"
    }
}
