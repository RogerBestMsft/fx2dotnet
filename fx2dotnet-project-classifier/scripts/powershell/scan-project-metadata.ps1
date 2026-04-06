param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath
)

if (-not (Test-Path $ProjectPath -PathType Leaf)) {
  Write-Error "Valid project path required"
  exit 1
}

Select-String -Path $ProjectPath -Pattern '<(OutputType|TargetFramework|TargetFrameworks|ProjectReference|PackageReference|Reference)' | ForEach-Object {
  $_.Line
}
