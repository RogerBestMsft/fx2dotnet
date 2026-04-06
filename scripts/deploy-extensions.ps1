param(
    [string]$ProjectDir = ".",
    [string]$Version = "latest",
    [string]$LocalSourceRoot,
    [switch]$KeepConfig,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$extensions = @(
    "fx2dotnet-support-core",
    "fx2dotnet-project-classifier",
    "fx2dotnet-assessment",
    "fx2dotnet-planner",
    "fx2dotnet-build-fix",
    "fx2dotnet-sdk-conversion",
    "fx2dotnet-package-compat",
    "fx2dotnet-multitarget",
    "fx2dotnet-web-route-inventory",
    "fx2dotnet-web-migration",
    "fx2dotnet-orchestrator"
)

$projectRoot = (Resolve-Path $ProjectDir).Path
if (-not (Test-Path (Join-Path $projectRoot ".specify"))) {
    throw "Spec-Kit project not found at $projectRoot."
}

if (-not (Get-Command specify -ErrorAction SilentlyContinue)) {
    throw "The 'specify' CLI is not available in PATH."
}

Push-Location $projectRoot
try {
    $installedExtensions = (& specify extension list | Out-String)

    foreach ($extensionId in $extensions) {
        if ($DryRun) {
            if ($LocalSourceRoot) {
                Write-Host "[dry-run] specify extension add --dev $(Join-Path $LocalSourceRoot $extensionId)"
            }
            else {
                Write-Host "[dry-run] specify extension add $extensionId --version $Version"
            }

            continue
        }

        if ($installedExtensions -match [regex]::Escape($extensionId)) {
            if ($KeepConfig) {
                & specify extension remove $extensionId --keep-config
            }
            else {
                & specify extension remove $extensionId
            }
        }

        if ($LocalSourceRoot) {
            $sourcePath = Join-Path $LocalSourceRoot $extensionId
            & specify extension add --dev $sourcePath
        }
        else {
            & specify extension add $extensionId --version $Version
        }
    }
}
finally {
    Pop-Location
}
