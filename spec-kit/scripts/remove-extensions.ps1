#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Remove all spec-kit fx-to-dotnet extensions from the local Spec Kit installation.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

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
    Write-Host "Removing $ext..."
    specify extension remove $ext 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  $ext was not installed, skipping"
    }
}

Write-Host "`nDone. All fx-to-dotnet extensions removed."
