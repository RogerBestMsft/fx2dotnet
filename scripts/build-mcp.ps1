param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectPath = Join-Path $RepoRoot "src/fx2dotnet/fx2dotnet.csproj"
$outputDir = Join-Path $RepoRoot "artifacts/bin/fx2dotnet/$Configuration"

if (-not (Test-Path $projectPath)) {
    throw "MCP project not found at $projectPath."
}

New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

Write-Host "Building Swick.Mcp.Fx2dotnet into $outputDir"
dotnet restore $projectPath
dotnet build $projectPath --configuration $Configuration --no-restore --output $outputDir

$builtFiles = @(Get-ChildItem -Path $outputDir -File)
if ($builtFiles.Count -eq 0) {
    throw "No build artifacts were produced in $outputDir."
}

Write-Host "Produced $($builtFiles.Count) files."
