param(
    [string]$ProjectDir = ".",
    [string]$ExtensionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "manifest-utils.ps1")

$projectRoot = (Resolve-Path $ProjectDir).Path
$installedRoot = Join-Path $projectRoot ".specify/extensions"

if (-not (Test-Path $installedRoot)) {
    throw "Installed extensions directory not found at $installedRoot."
}

$extensionRoots = if ($ExtensionId) {
    @((Get-Item (Join-Path $installedRoot $ExtensionId)))
}
else {
    @(Get-ChildItem -Path $installedRoot -Directory | Where-Object Name -like "fx2dotnet-*")
}

if ($extensionRoots.Count -eq 0) {
    throw "No installed fx2dotnet extensions were found beneath $installedRoot."
}

foreach ($extensionRoot in $extensionRoots) {
    $manifestPath = Join-Path $extensionRoot.FullName "extension.yml"
    if (-not (Test-Path $manifestPath)) {
        throw "extension.yml is missing for $($extensionRoot.Name)."
    }

    $manifest = Read-ExtensionManifest -Path $manifestPath

    foreach ($command in @($manifest.provides.commands)) {
        $commandPath = Join-Path $extensionRoot.FullName ([string]$command.file)
        if (-not (Test-Path $commandPath)) {
            throw "Installed command file missing for $($extensionRoot.Name): $($command.file)"
        }
    }

    foreach ($configEntry in @($manifest.provides.config)) {
        $configPath = Join-Path $extensionRoot.FullName ([string]$configEntry.name)
        if (-not (Test-Path $configPath)) {
            throw "Installed config file missing for $($extensionRoot.Name): $($configEntry.name)"
        }
    }

    $requiresLocalRuntime = @($manifest.requires.tools | Where-Object { $_.name -eq "Swick.Mcp.Fx2dotnet" }).Count -gt 0
    if ($requiresLocalRuntime -and -not (Test-Path (Join-Path $extensionRoot.FullName "artifacts"))) {
        throw "Installed runtime artifacts missing for $($extensionRoot.Name)."
    }

    Write-Host "Smoke test passed for $($extensionRoot.Name)"
}
