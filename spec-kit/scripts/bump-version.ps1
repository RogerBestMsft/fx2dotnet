#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Bump the version in all spec-kit extension.yml files.
.EXAMPLE
  scripts/bump-version.ps1 -Version 0.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$SpecKit = Split-Path -Parent $PSScriptRoot

$Extensions = @(
    'fx-to-dotnet'
    'fx-to-dotnet-assess'
    'fx-to-dotnet-plan'
    'fx-to-dotnet-sdk-convert'
    'fx-to-dotnet-build-fix'
    'fx-to-dotnet-package-compat'
    'fx-to-dotnet-multitarget'
    'fx-to-dotnet-web-migrate'
    'fx-to-dotnet-detect-project'
    'fx-to-dotnet-route-inventory'
    'fx-to-dotnet-policies'
)

foreach ($ext in $Extensions) {
    $yml = Join-Path $SpecKit $ext 'extension.yml'
    if (-not (Test-Path $yml)) {
        Write-Warning "$yml not found"
        continue
    }
    $content = Get-Content $yml -Raw
    $content = $content -replace 'version:\s*"?[^"\s]+"?', "version: `"$Version`""
    Set-Content -Path $yml -Value $content -NoNewline
    Write-Host "  $ext -> $Version"
}

Write-Host "Bumped all extensions to $Version"
