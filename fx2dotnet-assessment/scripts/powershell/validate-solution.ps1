param(
  [Parameter(Mandatory = $true)]
  [string]$SolutionPath
)

if (-not (Test-Path $SolutionPath -PathType Leaf)) {
  Write-Error "Valid .sln or .slnx path required"
  exit 1
}

if ($SolutionPath -notmatch '\.(sln|slnx)$') {
  Write-Error "Unsupported solution type: $SolutionPath"
  exit 1
}
