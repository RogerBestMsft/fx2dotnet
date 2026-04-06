param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath
)

if (Test-Path $InputPath -PathType Leaf) {
  if ($InputPath -match '\.(sln|slnx)$') {
    (Resolve-Path $InputPath).Path
    exit 0
  }

  Write-Error "Unsupported file type: $InputPath"
  exit 1
}

if (Test-Path $InputPath -PathType Container) {
  $solution = Get-ChildItem -Path $InputPath -Filter *.sln -Recurse -File | Select-Object -First 1
  if (-not $solution) {
    $solution = Get-ChildItem -Path $InputPath -Filter *.slnx -Recurse -File | Select-Object -First 1
  }

  if (-not $solution) {
    Write-Error "No .sln or .slnx found under $InputPath"
    exit 1
  }

  (Resolve-Path $solution.FullName).Path
  exit 0
}

Write-Error "Path not found: $InputPath"
exit 1
