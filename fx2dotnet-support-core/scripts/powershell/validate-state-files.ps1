param(
  [Parameter(Mandatory = $true)]
  [string]$StateRoot
)

'plan.md', 'analysis.md', 'package-updates.md' | ForEach-Object {
  $path = Join-Path $StateRoot $_
  if (-not (Test-Path $path)) {
    Write-Output "MISSING: $path"
  }
}
