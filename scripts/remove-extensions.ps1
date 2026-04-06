param(
    [string]$ProjectDir = ".",
    [switch]$KeepConfig,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$extensions = @(
    "fx2dotnet-orchestrator",
    "fx2dotnet-web-migration",
    "fx2dotnet-web-route-inventory",
    "fx2dotnet-multitarget",
    "fx2dotnet-package-compat",
    "fx2dotnet-sdk-conversion",
    "fx2dotnet-build-fix",
    "fx2dotnet-planner",
    "fx2dotnet-assessment",
    "fx2dotnet-project-classifier",
    "fx2dotnet-support-core"
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
        if ($installedExtensions -notmatch [regex]::Escape($extensionId)) {
            continue
        }

        if ($DryRun) {
            if ($KeepConfig) {
                Write-Host "[dry-run] specify extension remove $extensionId --keep-config"
            }
            else {
                Write-Host "[dry-run] specify extension remove $extensionId"
            }

            continue
        }

        if ($KeepConfig) {
            & specify extension remove $extensionId --keep-config
        }
        else {
            & specify extension remove $extensionId
        }
    }
}
finally {
    Pop-Location
}
