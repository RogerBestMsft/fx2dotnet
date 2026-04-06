param(
    [Parameter(Mandatory)]
    [string]$ExtensionId,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$OutputDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "releases"),
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "manifest-utils.ps1")

function Copy-PathIntoPackage {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$DestinationPath
    )

    $destinationParent = Split-Path -Path $DestinationPath -Parent
    if ($destinationParent) {
        New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
    }

    if ((Get-Item $SourcePath) -is [System.IO.DirectoryInfo]) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path (Join-Path $SourcePath "*") -Destination $DestinationPath -Recurse -Force
        return
    }

    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
}

$extensionRoot = Join-Path $RepoRoot $ExtensionId
$manifestPath = Join-Path $extensionRoot "extension.yml"
$artifactManifestPath = Join-Path $RepoRoot "packaging/artifact-manifests/$ExtensionId.json"

if (-not (Test-Path $manifestPath)) {
    throw "Manifest not found for $ExtensionId."
}

if (-not (Test-Path $artifactManifestPath)) {
    throw "Artifact manifest not found for $ExtensionId."
}

$extensionManifest = Read-ExtensionManifest -Path $manifestPath
$artifactManifest = Get-Content -Path $artifactManifestPath -Raw | ConvertFrom-Json

if (-not $Version) {
    $Version = [string]$extensionManifest.extension.version
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    throw "Unable to determine a version for $ExtensionId."
}

New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("{0}-{1}-{2}" -f $ExtensionId, $Version, [guid]::NewGuid().ToString("n"))
New-Item -Path $stagingRoot -ItemType Directory -Force | Out-Null

try {
    foreach ($include in @($artifactManifest.includes)) {
        $relativePath = ($include.path -replace "/", "\")
        $sourcePath = Join-Path $extensionRoot $relativePath

        if (-not (Test-Path $sourcePath)) {
            if ($include.required) {
                throw "Required package path missing for ${ExtensionId}: $relativePath"
            }

            continue
        }

        $destinationPath = Join-Path $stagingRoot $relativePath
        Copy-PathIntoPackage -SourcePath $sourcePath -DestinationPath $destinationPath
    }

    $zipPath = Join-Path $OutputDir ("{0}-{1}.zip" -f $ExtensionId, $Version)
    $checksumPath = "$zipPath.sha256"

    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }

    if (Test-Path $checksumPath) {
        Remove-Item -Path $checksumPath -Force
    }

    Compress-Archive -Path (Join-Path $stagingRoot "*") -DestinationPath $zipPath -Force
    $hash = Get-FileHash -Path $zipPath -Algorithm SHA256
    "{0}  {1}" -f $hash.Hash.ToLowerInvariant(), (Split-Path -Path $zipPath -Leaf) | Set-Content -Path $checksumPath -Encoding ascii

    Write-Host "Packaged $ExtensionId $Version to $zipPath"
    Write-Host "Checksum written to $checksumPath"
}
finally {
    if (Test-Path $stagingRoot) {
        Remove-Item -Path $stagingRoot -Recurse -Force
    }
}
