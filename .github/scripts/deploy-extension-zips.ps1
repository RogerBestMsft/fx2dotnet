[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ZipDirectory = "artifacts/extensions"
)

$ErrorActionPreference = "Stop"

$specify = Get-Command -Name specify -ErrorAction SilentlyContinue
if (-not $specify) {
    Write-Error "The 'specify' CLI is not installed or not on PATH."
}

$zipFiles = Get-ChildItem -Path $ZipDirectory -Filter *.zip -File
if (-not $zipFiles) {
    Write-Error "No zip files found in $ZipDirectory"
}

foreach ($zipFile in $zipFiles) {
    $extensionName = [System.IO.Path]::GetFileNameWithoutExtension($zipFile.Name)
    Write-Host "Deploying $extensionName from $($zipFile.FullName)"
    specify extension add $extensionName --from $zipFile.FullName
}

Write-Host "Deployed $($zipFiles.Count) extension bundle(s)."
