param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$CatalogPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "catalogs/catalog.json"),
    [string]$CommunityCatalogPath,
    [string[]]$ExtensionIds,
    [string]$ReleaseBaseUrl = "https://github.com/RogerBestMSFT/fx2dotnet/releases/download",
    [string]$CatalogUrl = "https://github.com/RogerBestMSFT/fx2dotnet/raw/main/catalogs/catalog.json",
    [switch]$InstallAllowed,
    [switch]$IncludeCommunityMirror
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "manifest-utils.ps1")

function Load-JsonFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $null
    }

    return (Get-Content -Path $Path -Raw | ConvertFrom-Json)
}

function Ensure-CatalogShell {
    param(
        [string]$ExistingCatalogPath,
        [string]$CatalogUrlValue,
        [bool]$InstallAllowedValue
    )

    $existingCatalog = Load-JsonFile -Path $ExistingCatalogPath
    if ($null -ne $existingCatalog) {
        if ($null -eq $existingCatalog.extensions) {
            $existingCatalog | Add-Member -MemberType NoteProperty -Name extensions -Value ([ordered]@{})
        }

        return $existingCatalog
    }

    return [ordered]@{
        schema_version = "1.0"
        updated_at     = [DateTime]::UtcNow.ToString("o")
        catalog_url    = $CatalogUrlValue
        install_allowed = $InstallAllowedValue
        extensions     = [ordered]@{}
    }
}

if (-not $ExtensionIds -or $ExtensionIds.Count -eq 0) {
    $ExtensionIds = @(Get-ChildItem -Path $RepoRoot -Directory |
        Where-Object { $_.Name -like "fx2dotnet-*" -and (Test-Path (Join-Path $_.FullName "extension.yml")) } |
        Sort-Object Name |
        ForEach-Object Name)
}

$catalog = Ensure-CatalogShell -ExistingCatalogPath $CatalogPath -CatalogUrlValue $CatalogUrl -InstallAllowedValue $InstallAllowed.IsPresent
$communityCatalog = $null
if ($IncludeCommunityMirror) {
    if (-not $CommunityCatalogPath) {
        $CommunityCatalogPath = Join-Path $RepoRoot "catalogs/community-catalog.json"
    }

    $communityCatalog = Ensure-CatalogShell -ExistingCatalogPath $CommunityCatalogPath -CatalogUrlValue "https://github.com/RogerBestMSFT/fx2dotnet/raw/main/catalogs/community-catalog.json" -InstallAllowedValue $false
}

foreach ($extensionId in $ExtensionIds) {
    $manifestPath = Join-Path $RepoRoot "$extensionId/extension.yml"
    if (-not (Test-Path $manifestPath)) {
        throw "Manifest not found for $extensionId."
    }

    $manifest = Read-ExtensionManifest -Path $manifestPath
    $version = [string]$manifest.extension.version
    $tagName = "{0}-v{1}" -f $extensionId, $version
    $downloadUrl = "{0}/{1}/{2}-{3}.zip" -f $ReleaseBaseUrl.TrimEnd('/'), $tagName, $extensionId, $version
    $hookCount = if ($null -eq $manifest.hooks) { 0 } else { @($manifest.hooks.Keys).Count }

    $entry = [ordered]@{
        id            = [string]$manifest.extension.id
        name          = [string]$manifest.extension.name
        version       = $version
        description   = [string]$manifest.extension.description
        author        = [string]$manifest.extension.author
        repository    = [string]$manifest.extension.repository
        license       = [string]$manifest.extension.license
        homepage      = [string]$manifest.extension.homepage
        download_url  = $downloadUrl
        requires      = $manifest.requires
        provides      = [ordered]@{
            commands      = @(@($manifest.provides.commands) | ForEach-Object { $_.name })
            command_count = @($manifest.provides.commands).Count
            hooks         = if ($hookCount -eq 0) { @() } else { @($manifest.hooks.Keys) }
            hook_count    = $hookCount
        }
        tags          = @($manifest.tags)
        verified      = $true
        created_at    = [DateTime]::UtcNow.ToString("o")
        updated_at    = [DateTime]::UtcNow.ToString("o")
    }

    $catalog.extensions[$extensionId] = $entry
    if ($null -ne $communityCatalog) {
        $communityCatalog.extensions[$extensionId] = $entry
    }
}

$catalog.updated_at = [DateTime]::UtcNow.ToString("o")
New-Item -Path (Split-Path -Path $CatalogPath -Parent) -ItemType Directory -Force | Out-Null
$catalog | ConvertTo-Json -Depth 20 | Set-Content -Path $CatalogPath -Encoding utf8
Write-Host "Updated internal catalog at $CatalogPath"

if ($null -ne $communityCatalog) {
    $communityCatalog.updated_at = [DateTime]::UtcNow.ToString("o")
    New-Item -Path (Split-Path -Path $CommunityCatalogPath -Parent) -ItemType Directory -Force | Out-Null
    $communityCatalog | ConvertTo-Json -Depth 20 | Set-Content -Path $CommunityCatalogPath -Encoding utf8
    Write-Host "Updated community catalog at $CommunityCatalogPath"
}
