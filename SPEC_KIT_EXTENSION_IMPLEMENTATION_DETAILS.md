# Spec-Kit fx2dotnet Extension Suite — Implementation Details

**Document Version**: 1.0  
**Date**: April 3, 2026  
**Purpose**: Technical specifications, scripts, code templates, and CI/CD automation for implementing the fx2dotnet extension suite.

> **This document is a companion to**: [SPEC_KIT_EXTENSION_PLAN.md](SPEC_KIT_EXTENSION_PLAN.md) — See the plan for architecture decisions, phase descriptions, timelines, risks, and verification criteria. This document contains the corresponding executable details for each plan section.

> **Execution backlog**: [SPEC_KIT_EXTENSION_WORK_ITEMS.md](SPEC_KIT_EXTENSION_WORK_ITEMS.md) tracks the concrete work items to execute and status over time.

---

## Table of Contents

1. [Deployment & Removal Scripts](#deployment--removal-scripts)
2. [Per-Extension Implementation Map](#per-extension-implementation-map)
3. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
4. [Build Scripts](#build-scripts)
5. [Manifest Templates](#manifest-templates)
6. [Extension Command Templates](#extension-command-templates)
7. [Validation & Testing Scripts](#validation--testing-scripts)
8. [Configuration Templates](#configuration-templates)
9. [State Contract Specifications](#state-contract-specifications)
10. [MCP Availability Continuity Runbook](#mcp-availability-continuity-runbook)

---

## Deployment & Removal Scripts

### deploy-extensions.sh (Bash/Linux/macOS)

**Location**: `scripts/deploy-extensions.sh`

**Purpose**: Install all fx2dotnet extensions from catalog (or local sources) into a Spec-Kit project in dependency order.

```bash
#!/bin/bash
# Deploy all fx2dotnet extensions to a Spec-Kit project
# Usage: ./scripts/deploy-extensions.sh [--project-dir PATH] [--version VERSION] [--keep-config] [--dry-run]

set -e

PROJECT_DIR="${PROJECT_DIR:-.}"
VERSION="${VERSION:-latest}"
KEEP_CONFIG=false
DRY_RUN=false
CATALOG_URL="https://internal-repo.example.com/catalogs/catalog.json"

# Extension installation order (dependency-aware)
EXTENSIONS=(
  "fx2dotnet-support-core"
  "fx2dotnet-project-classifier"
  "fx2dotnet-assessment"
  "fx2dotnet-planner"
  "fx2dotnet-build-fix"
  "fx2dotnet-sdk-conversion"
  "fx2dotnet-package-compat"
  "fx2dotnet-multitarget"
  "fx2dotnet-web-migration"
  "fx2dotnet-web-route-inventory"
  "fx2dotnet-orchestrator"
)

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --keep-config) KEEP_CONFIG=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "==============================================="
echo "  fx2dotnet Extension Suite - Deployment"
echo "==============================================="
echo "Project Dir: $PROJECT_DIR"
echo "Version: $VERSION"
echo "Keep Config: $KEEP_CONFIG"
echo "Dry Run: $DRY_RUN"
echo ""

# Verify project exists
if [ ! -d "$PROJECT_DIR/.specify" ]; then
  echo "ERROR: Spec-Kit project not found at $PROJECT_DIR"
  echo "Please run: specify init --project-name <name>"
  exit 1
fi

# Function to install extension
install_extension() {
  local ext_id=$1
  local ext_name="${ext_id//-/ }"
  
  echo "→ Installing $ext_name ($ext_id)..."
  
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would execute: specify extension add $ext_id --version $VERSION"
    return 0
  fi
  
  # Remove previous version if exists (respecting --keep-config)
  if specify extension list 2>/dev/null | grep -q "$ext_id"; then
    echo "  Removing previous version..."
    if [ "$KEEP_CONFIG" = true ]; then
      specify extension remove "$ext_id" --keep-config 2>/dev/null || true
    else
      specify extension remove "$ext_id" 2>/dev/null || true
    fi
    sleep 1  # Allow filesystem to settle
  fi
  
  # Install extension
  if specify extension add "$ext_id" --version "$VERSION" 2>/dev/null; then
    echo "  ✓ Installation successful"
    return 0
  else
    echo "  ✗ Installation FAILED"
    return 1
  fi
}

# Deploy all extensions
FAILED_EXTENSIONS=()
INSTALLED_COUNT=0

for ext in "${EXTENSIONS[@]}"; do
  if install_extension "$ext"; then
    ((INSTALLED_COUNT++))
  else
    FAILED_EXTENSIONS+=("$ext")
  fi
done

echo ""
echo "==============================================="
echo "  Deployment Summary"
echo "==============================================="
echo "Installed: $INSTALLED_COUNT/${#EXTENSIONS[@]}"

if [ ${#FAILED_EXTENSIONS[@]} -gt 0 ]; then
  echo ""
  echo "Failed Extensions:"
  for ext in "${FAILED_EXTENSIONS[@]}"; do
    echo "  ✗ $ext"
  done
  exit 1
else
  echo "✓ All extensions deployed successfully"
  echo ""
  echo "Next steps:"
  echo "  1. Verify installation:"
  echo "     specify extension list"
  echo "  2. Configure extensions:"
  echo "     Edit .specify/extensions/{ext-id}/{ext-id}-config.yml"
  echo "  3. Run orchestrator:"
  echo "     /speckit.fx2dotnet-orchestrator.start"
  exit 0
fi
```

### deploy-extensions.ps1 (PowerShell/Windows)

**Location**: `scripts/deploy-extensions.ps1`

**Purpose**: PowerShell equivalent with Windows-specific error handling and formatting.

```powershell
<#
.SYNOPSIS
Deploy all fx2dotnet extensions to a Spec-Kit project
.DESCRIPTION
Installs all fx2dotnet extensions in dependency order with rollback support
.PARAMETER ProjectDir
Path to the Spec-Kit project root (default: .)
.PARAMETER Version
Extension version to install, or 'latest' (default: latest)
.PARAMETER KeepConfig
Preserve existing extension configurations during reinstall
.PARAMETER DryRun
Show what would be done without actually installing
.EXAMPLE
.\deploy-extensions.ps1 -ProjectDir "C:\my-project" -Version "1.0.0"
#>

param(
  [string]$ProjectDir = ".",
  [string]$Version = "latest",
  [switch]$KeepConfig,
  [switch]$DryRun
)

# Extension installation order (dependency-aware)
$Extensions = @(
  "fx2dotnet-support-core"
  "fx2dotnet-project-classifier"
  "fx2dotnet-assessment"
  "fx2dotnet-planner"
  "fx2dotnet-build-fix"
  "fx2dotnet-sdk-conversion"
  "fx2dotnet-package-compat"
  "fx2dotnet-multitarget"
  "fx2dotnet-web-migration"
  "fx2dotnet-web-route-inventory"
  "fx2dotnet-orchestrator"
)

$CatalogUrl = "https://internal-repo.example.com/catalogs/catalog.json"
$ProjectDir = Resolve-Path $ProjectDir

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  fx2dotnet Extension Suite - Deployment" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Project Dir: $ProjectDir"
Write-Host "Version: $Version"
Write-Host "Keep Config: $KeepConfig"
Write-Host "Dry Run: $DryRun"
Write-Host ""

# Verify project exists
if (-not (Test-Path "$ProjectDir\.specify")) {
  Write-Host "ERROR: Spec-Kit project not found at $ProjectDir" -ForegroundColor Red
  Write-Host "Please run: specify init --project-name <name>" -ForegroundColor Yellow
  exit 1
}

# Function to install extension
function Install-Extension {
  param([string]$ExtId)
  
  $ExtName = $ExtId -replace '-', ' '
  Write-Host "→ Installing $ExtName ($ExtId)..." -ForegroundColor White
  
  if ($DryRun) {
    Write-Host "  [DRY RUN] Would execute: specify extension add $ExtId --version $Version" -ForegroundColor Gray
    return $true
  }
  
  # Check if extension already exists
  $InstalledExt = specify extension list | Select-String $ExtId
  if ($InstalledExt) {
    Write-Host "  Removing previous version..." -ForegroundColor Gray
    if ($KeepConfig) {
      specify extension remove $ExtId --keep-config 2>$null
    } else {
      specify extension remove $ExtId 2>$null
    }
    Start-Sleep -Seconds 1  # Allow filesystem to settle
  }
  
  # Install extension
  try {
    specify extension add $ExtId --version $Version 2>$null
    Write-Host "  ✓ Installation successful" -ForegroundColor Green
    return $true
  } catch {
    Write-Host "  ✗ Installation FAILED: $_" -ForegroundColor Red
    return $false
  }
}

# Deploy all extensions
$FailedExtensions = @()
$InstalledCount = 0

foreach ($ext in $Extensions) {
  if (Install-Extension -ExtId $ext) {
    $InstalledCount++
  } else {
    $FailedExtensions += $ext
  }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Installed: $InstalledCount/$($Extensions.Count)"

if ($FailedExtensions.Count -gt 0) {
  Write-Host ""
  Write-Host "Failed Extensions:" -ForegroundColor Red
  foreach ($ext in $FailedExtensions) {
    Write-Host "  ✗ $ext" -ForegroundColor Red
  }
  exit 1
} else {
  Write-Host "✓ All extensions deployed successfully" -ForegroundColor Green
  Write-Host ""
  Write-Host "Next steps:" -ForegroundColor Yellow
  Write-Host "  1. Verify installation:"
  Write-Host "     specify extension list" -ForegroundColor Cyan
  Write-Host "  2. Configure extensions:"
  Write-Host "     Edit .specify/extensions/{ext-id}/{ext-id}-config.yml" -ForegroundColor Cyan
  Write-Host "  3. Run orchestrator:"
  Write-Host "     /speckit.fx2dotnet-orchestrator.start" -ForegroundColor Cyan
  exit 0
}
```

### remove-extensions.sh (Bash/Linux/macOS)

**Location**: `scripts/remove-extensions.sh`

**Purpose**: Uninstall all fx2dotnet extensions with optional config preservation.

```bash
#!/bin/bash
# Remove all fx2dotnet extensions from a Spec-Kit project
# Usage: ./scripts/remove-extensions.sh [--project-dir PATH] [--keep-config] [--dry-run]

set -e

PROJECT_DIR="${PROJECT_DIR:-.}"
KEEP_CONFIG=false
DRY_RUN=false

# All fx2dotnet extensions (order irrelevant for removal)
EXTENSIONS=(
  "fx2dotnet-orchestrator"
  "fx2dotnet-web-route-inventory"
  "fx2dotnet-web-migration"
  "fx2dotnet-multitarget"
  "fx2dotnet-package-compat"
  "fx2dotnet-sdk-conversion"
  "fx2dotnet-build-fix"
  "fx2dotnet-planner"
  "fx2dotnet-assessment"
  "fx2dotnet-project-classifier"
  "fx2dotnet-support-core"
)

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --keep-config) KEEP_CONFIG=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "==============================================="
echo "  fx2dotnet Extension Suite - Removal"
echo "==============================================="
echo "Project Dir: $PROJECT_DIR"
echo "Keep Config: $KEEP_CONFIG"
echo "Dry Run: $DRY_RUN"
echo ""

# Verify project exists
if [ ! -d "$PROJECT_DIR/.specify" ]; then
  echo "ERROR: Spec-Kit project not found at $PROJECT_DIR"
  exit 1
fi

# Function to remove extension
remove_extension() {
  local ext_id=$1
  local ext_name="${ext_id//-/ }"
  
  # Check if installed
  if ! specify extension list 2>/dev/null | grep -q "$ext_id"; then
    echo "→ $ext_name ($ext_id) - NOT INSTALLED, skipping"
    return 0
  fi
  
  echo "→ Removing $ext_name ($ext_id)..."
  
  if [ "$DRY_RUN" = true ]; then
    if [ "$KEEP_CONFIG" = true ]; then
      echo "  [DRY RUN] Would execute: specify extension remove $ext_id --keep-config"
    else
      echo "  [DRY RUN] Would execute: specify extension remove $ext_id"
    fi
    return 0
  fi
  
  # Remove extension
  if [ "$KEEP_CONFIG" = true ]; then
    specify extension remove "$ext_id" --keep-config 2>/dev/null && echo "  ✓ Removed (config preserved)" || echo "  ✗ Removal FAILED"
  else
    specify extension remove "$ext_id" 2>/dev/null && echo "  ✓ Removed completely" || echo "  ✗ Removal FAILED"
  fi
}

# Remove all extensions
REMOVED_COUNT=0

for ext in "${EXTENSIONS[@]}"; do
  if remove_extension "$ext"; then
    ((REMOVED_COUNT++))
  fi
done

echo ""
echo "==============================================="
echo "  Removal Summary"
echo "==============================================="
echo "Processed: $REMOVED_COUNT extensions"

if [ "$KEEP_CONFIG" = true ]; then
  echo ""
  echo "Configuration preserved at:"
  echo "  .specify/extensions/{ext-id}/{ext-id}-config.yml"
  echo ""
  echo "To reinstall with existing config:"
  echo "  ./scripts/deploy-extensions.sh --keep-config"
fi

echo "✓ Removal complete"
```

### remove-extensions.ps1 (PowerShell/Windows)

**Location**: `scripts/remove-extensions.ps1`

**Purpose**: PowerShell equivalent for safe uninstall with config backup.

```powershell
<#
.SYNOPSIS
Remove all fx2dotnet extensions from a Spec-Kit project
.DESCRIPTION
Uninstalls all fx2dotnet extensions with optional config preservation
.PARAMETER ProjectDir
Path to the Spec-Kit project root (default: .)
.PARAMETER KeepConfig
Preserve extension configurations for later reinstall
.PARAMETER DryRun
Show what would be done without actually removing
.EXAMPLE
.\remove-extensions.ps1 -ProjectDir "C:\my-project" -KeepConfig
#>

param(
  [string]$ProjectDir = ".",
  [switch]$KeepConfig,
  [switch]$DryRun
)

# All fx2dotnet extensions (order irrelevant for removal)
$Extensions = @(
  "fx2dotnet-orchestrator"
  "fx2dotnet-web-route-inventory"
  "fx2dotnet-web-migration"
  "fx2dotnet-multitarget"
  "fx2dotnet-package-compat"
  "fx2dotnet-sdk-conversion"
  "fx2dotnet-build-fix"
  "fx2dotnet-planner"
  "fx2dotnet-assessment"
  "fx2dotnet-project-classifier"
  "fx2dotnet-support-core"
)

$ProjectDir = Resolve-Path $ProjectDir

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  fx2dotnet Extension Suite - Removal" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Project Dir: $ProjectDir"
Write-Host "Keep Config: $KeepConfig"
Write-Host "Dry Run: $DryRun"
Write-Host ""

# Verify project exists
if (-not (Test-Path "$ProjectDir\.specify")) {
  Write-Host "ERROR: Spec-Kit project not found at $ProjectDir" -ForegroundColor Red
  exit 1
}

# Function to remove extension
function Remove-Extension {
  param([string]$ExtId)
  
  $ExtName = $ExtId -replace '-', ' '
  
  # Check if installed
  $InstalledExt = specify extension list 2>$null | Select-String $ExtId
  if (-not $InstalledExt) {
    Write-Host "→ $ExtName ($ExtId) - NOT INSTALLED, skipping" -ForegroundColor Gray
    return $true
  }
  
  Write-Host "→ Removing $ExtName ($ExtId)..." -ForegroundColor White
  
  if ($DryRun) {
    if ($KeepConfig) {
      Write-Host "  [DRY RUN] Would execute: specify extension remove $ExtId --keep-config" -ForegroundColor Gray
    } else {
      Write-Host "  [DRY RUN] Would execute: specify extension remove $ExtId" -ForegroundColor Gray
    }
    return $true
  }
  
  try {
    if ($KeepConfig) {
      specify extension remove $ExtId --keep-config 2>$null
      Write-Host "  ✓ Removed (config preserved)" -ForegroundColor Green
    } else {
      specify extension remove $ExtId 2>$null
      Write-Host "  ✓ Removed completely" -ForegroundColor Green
    }
    return $true
  } catch {
    Write-Host "  ✗ Removal FAILED: $_" -ForegroundColor Red
    return $false
  }
}

# Remove all extensions
$RemovedCount = 0

foreach ($ext in $Extensions) {
  if (Remove-Extension -ExtId $ext) {
    $RemovedCount++
  }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Removal Summary" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Processed: $RemovedCount extensions"

if ($KeepConfig) {
  Write-Host ""
  Write-Host "Configuration preserved at:" -ForegroundColor Yellow
  Write-Host "  .specify/extensions/{ext-id}/{ext-id}-config.yml"
  Write-Host ""
  Write-Host "To reinstall with existing config:" -ForegroundColor Yellow
  Write-Host "  .\deploy-extensions.ps1 -KeepConfig" -ForegroundColor Cyan
}

Write-Host "✓ Removal complete" -ForegroundColor Green
```

---

## Per-Extension Implementation Map

This section maps each planned extension to the concrete files it should contain so reviewers can trace architecture to implementation one-to-one.

### Standard Extension Layout

Every extension should follow this baseline structure:

```text
fx2dotnet-{extension-name}/
├── extension.yml
├── commands/
├── docs/
├── scripts/
│   ├── bash/
│   └── powershell/
├── artifacts/                    # only when MCP/runtime assets are required
├── fx2dotnet-{extension-name}-config.template.yml
└── .extensionignore
```

### 1) fx2dotnet-support-core

**Expected files**:

```text
fx2dotnet-support-core/
├── extension.yml
├── commands/
│   ├── validate-state-contract.md
│   ├── resolve-solution-context.md
│   └── invoke-mcp-wrapper.md
├── docs/
│   ├── state-contract.md
│   └── shared-conventions.md
├── scripts/
│   ├── bash/
│   │   ├── resolve-solution-path.sh
│   │   └── validate-state-files.sh
│   └── powershell/
│       ├── resolve-solution-path.ps1
│       └── validate-state-files.ps1
└── fx2dotnet-support-core-config.template.yml
```

**Primary responsibility**:
- Shared state validation, path normalization, common diagnostics, and reusable wrappers.

**Consumed by**:
- All other extensions.

### 2) fx2dotnet-project-classifier

**Expected files**:

```text
fx2dotnet-project-classifier/
├── extension.yml
├── commands/
│   ├── classify-project.md
│   └── detect-sdk-style-status.md
├── docs/
│   └── classification-rules.md
├── scripts/
│   ├── bash/scan-project-metadata.sh
│   └── powershell/scan-project-metadata.ps1
└── fx2dotnet-project-classifier-config.template.yml
```

**Primary responsibility**:
- Project-type classification and conversion eligibility detection.

**Produces**:
- Classification output consumed by assessment and planner.

### 3) fx2dotnet-assessment

**Expected files**:

```text
fx2dotnet-assessment/
├── extension.yml
├── commands/
│   ├── run.md
│   ├── compute-layers.md
│   └── collect-package-baseline.md
├── docs/
│   └── assessment-output-format.md
├── scripts/
│   ├── bash/validate-solution.sh
│   └── powershell/validate-solution.ps1
├── artifacts/
│   └── bin/fx2dotnet/
└── fx2dotnet-assessment-config.template.yml
```

**Primary responsibility**:
- Produce `.fx2dotnet/analysis.md` and seed `.fx2dotnet/package-updates.md`.

**External dependencies**:
- App modernization MCP and Swick MCP.

### 4) fx2dotnet-planner

**Expected files**:

```text
fx2dotnet-planner/
├── extension.yml
├── commands/
│   ├── generate-plan.md
│   └── summarize-risks.md
├── docs/
│   └── planning-rules.md
└── fx2dotnet-planner-config.template.yml
```

**Primary responsibility**:
- Transform assessment outputs into executable migration order and risk chunks.

### 5) fx2dotnet-build-fix

**Expected files**:

```text
fx2dotnet-build-fix/
├── extension.yml
├── commands/
│   ├── diagnose-build.md
│   ├── apply-fix-pattern.md
│   └── retry-build.md
├── docs/
│   └── build-failure-taxonomy.md
├── scripts/
│   ├── bash/run-build.sh
│   └── powershell/run-build.ps1
└── fx2dotnet-build-fix-config.template.yml
```

**Primary responsibility**:
- Shared remediation loop for restore/build issues.

### 6) fx2dotnet-sdk-conversion

**Expected files**:

```text
fx2dotnet-sdk-conversion/
├── extension.yml
├── commands/
│   ├── convert-project.md
│   ├── validate-conversion.md
│   └── normalize-project-file.md
├── docs/
│   └── sdk-conversion-rules.md
├── artifacts/
│   └── bin/fx2dotnet/
└── fx2dotnet-sdk-conversion-config.template.yml
```

**Primary responsibility**:
- Execute SDK-style conversion and record project-level conversion state.

### 7) fx2dotnet-package-compat

**Expected files**:

```text
fx2dotnet-package-compat/
├── extension.yml
├── commands/
│   ├── apply-package-chunk.md
│   ├── validate-package-updates.md
│   └── record-package-status.md
├── docs/
│   └── package-risk-model.md
├── artifacts/
│   └── bin/fx2dotnet/
└── fx2dotnet-package-compat-config.template.yml
```

**Primary responsibility**:
- Apply package compatibility changes in ordered chunks and update package execution ledger.

### 8) fx2dotnet-multitarget

**Expected files**:

```text
fx2dotnet-multitarget/
├── extension.yml
├── commands/
│   ├── add-target-frameworks.md
│   ├── validate-api-gaps.md
│   └── record-multitarget-state.md
├── docs/
│   └── multitarget-strategy.md
└── fx2dotnet-multitarget-config.template.yml
```

**Primary responsibility**:
- Add modern TFMs and track compatibility remediation.

### 9) fx2dotnet-web-route-inventory

**Expected files**:

```text
fx2dotnet-web-route-inventory/
├── extension.yml
├── commands/
│   ├── inventory-routes.md
│   ├── inventory-handlers.md
│   └── inventory-modules.md
├── docs/
│   └── route-inventory-output.md
└── fx2dotnet-web-route-inventory-config.template.yml
```

**Primary responsibility**:
- Generate migration-ready route and handler inventory for legacy web apps.

### 10) fx2dotnet-web-migration

**Expected files**:

```text
fx2dotnet-web-migration/
├── extension.yml
├── commands/
│   ├── scaffold-core-host.md
│   ├── port-routes.md
│   └── validate-web-host.md
├── docs/
│   ├── systemweb-adapters-usage.md
│   └── web-migration-checklist.md
└── fx2dotnet-web-migration-config.template.yml
```

**Primary responsibility**:
- Side-by-side ASP.NET Core host migration and route-by-route transition support.

### 11) fx2dotnet-orchestrator

**Expected files**:

```text
fx2dotnet-orchestrator/
├── extension.yml
├── commands/
│   ├── start.md
│   ├── resume.md
│   ├── show-status.md
│   └── validate-phase-gates.md
├── docs/
│   └── orchestration-lifecycle.md
└── fx2dotnet-orchestrator-config.template.yml
```

**Primary responsibility**:
- Entry-point command surface and full lifecycle coordination of all phases.

### Per-Extension Operational Matrix

| Extension | Primary Commands | State Files Written | MCP Dependencies | Config Template | Key Output |
|-----------|------------------|---------------------|------------------|-----------------|------------|
| `fx2dotnet-support-core` | `validate-state-contract`, `resolve-solution-context`, `invoke-mcp-wrapper` | None directly owned; validates all `.fx2dotnet/*.md` contracts | Optional wrapper use only | `fx2dotnet-support-core-config.template.yml` | Shared execution helpers and contract enforcement |
| `fx2dotnet-project-classifier` | `classify-project`, `detect-sdk-style-status` | Indirect contribution to `analysis.md` via structured classification output | None required | `fx2dotnet-project-classifier-config.template.yml` | Project-type and eligibility classification |
| `fx2dotnet-assessment` | `run`, `compute-layers`, `collect-package-baseline` | `.fx2dotnet/analysis.md`, `.fx2dotnet/package-updates.md` | `Microsoft.GitHubCopilot.AppModernization.Mcp`, `Swick.Mcp.Fx2dotnet` | `fx2dotnet-assessment-config.template.yml` | Solution inventory, dependency layers, package baseline |
| `fx2dotnet-planner` | `generate-plan`, `summarize-risks` | `.fx2dotnet/plan.md` | None required | `fx2dotnet-planner-config.template.yml` | Ordered migration plan and risk sequencing |
| `fx2dotnet-build-fix` | `diagnose-build`, `apply-fix-pattern`, `retry-build` | `.fx2dotnet/{ProjectStateFile}.md` under `## Build Fix` (keyed by `projectId`) | None required | `fx2dotnet-build-fix-config.template.yml` | Build failure diagnosis and remediation status |
| `fx2dotnet-sdk-conversion` | `convert-project`, `validate-conversion`, `normalize-project-file` | `.fx2dotnet/{ProjectStateFile}.md` under `## SDK Conversion` (keyed by `projectId`) | `Microsoft.GitHubCopilot.AppModernization.Mcp`, `Swick.Mcp.Fx2dotnet` | `fx2dotnet-sdk-conversion-config.template.yml` | SDK-style normalized project state |
| `fx2dotnet-package-compat` | `apply-package-chunk`, `validate-package-updates`, `record-package-status` | `.fx2dotnet/package-updates.md` | `Swick.Mcp.Fx2dotnet` | `fx2dotnet-package-compat-config.template.yml` | Executed package update ledger |
| `fx2dotnet-multitarget` | `add-target-frameworks`, `validate-api-gaps`, `record-multitarget-state` | `.fx2dotnet/{ProjectStateFile}.md` under `## Multitarget` (keyed by `projectId`) | None required | `fx2dotnet-multitarget-config.template.yml` | Project multitargeting state and API-gap tracking |
| `fx2dotnet-web-route-inventory` | `inventory-routes`, `inventory-handlers`, `inventory-modules` | Route inventory artifacts referenced by web migration docs/state | None required | `fx2dotnet-web-route-inventory-config.template.yml` | Extracted route/handler/module inventory |
| `fx2dotnet-web-migration` | `scaffold-core-host`, `port-routes`, `validate-web-host` | `.fx2dotnet/{ProjectStateFile}.md` under `## Web Migration` (keyed by `projectId`) | None required | `fx2dotnet-web-migration-config.template.yml` | Side-by-side ASP.NET Core host migration state |
| `fx2dotnet-orchestrator` | `start`, `resume`, `show-status`, `validate-phase-gates` | `.fx2dotnet/plan.md` (phase + per-project matrix keyed by `projectId`) | None required | `fx2dotnet-orchestrator-config.template.yml` | Workflow coordination, phase checkpoints, resume control |

### Matrix Usage Notes

1. `State Files Written` identifies ownership, not every file an extension may read.
2. Support extensions may emit transient helper outputs, but ownership remains with the primary phase extension.
3. MCP dependencies listed here are the runtime-critical tool contracts that must be available or replaced by the continuity plan.
4. This matrix is the fastest review surface for validating extension boundaries against the plan.

### Multi-Project Identity and File Naming

Use these rules across all extension commands and state writers:

1. `projectId` is the canonical identity and equals normalized path from solution root to `.csproj` (for example `src/Web/Web.csproj`).
2. `ProjectStateFile` is derived from display project name and is collision-safe.
3. If duplicate file stems exist, append a short deterministic hash from `projectId` to avoid collisions (example: `Web-a1b2c3d4.md`, `Web-f9e8d7c6.md`).
4. Every per-project section must include both display name and `projectId`.
5. Cross-file validation must enforce the same `projectId` set across `analysis.md`, `plan.md`, `package-updates.md`, and per-project files.

### Command Naming Recommendations

Use a stable naming convention across all extensions:

```text
speckit.fx2dotnet-{extension}.{action}
```

Examples:
- `speckit.fx2dotnet-assessment.run`
- `speckit.fx2dotnet-sdk-conversion.convert-project`
- `speckit.fx2dotnet-build-fix.retry-build`
- `speckit.fx2dotnet-orchestrator.resume`

### Traceability Rule

For every extension in the plan:

1. `extension.yml` must identify the command surface.
2. `commands/` must match the planned responsibilities.
3. `docs/` must explain extension-specific rules and outputs.
4. `scripts/` and `artifacts/` must exist only when operationally required.
5. Config templates must expose only the extension-owned runtime knobs.

This mapping is the implementation-side reference for the per-extension behavior section in [SPEC_KIT_EXTENSION_PLAN.md](SPEC_KIT_EXTENSION_PLAN.md).

---

## CI/CD Pipeline Configuration

### GitHub Actions Workflow (`.github/workflows/release-extensions.yml`)

**Purpose**: Automated build → validate → package → publish → catalog flow triggered by version tags.

```yaml
name: Release fx2dotnet Extensions

on:
  push:
    tags:
      - 'fx2dotnet-*-v*'  # Matches: fx2dotnet-assessment-v1.0.0

permissions:
  contents: write
  packages: write

jobs:
  parse-tag:
    runs-on: ubuntu-latest
    outputs:
      extension-id: ${{ steps.parse.outputs.extension-id }}
      version: ${{ steps.parse.outputs.version }}
      extension-dir: ${{ steps.parse.outputs.extension-dir }}
    steps:
      - name: Parse tag
        id: parse
        run: |
          TAG="${{ github.ref_name }}"
          # Extract: fx2dotnet-{id}-v{version}
          if [[ $TAG =~ ^fx2dotnet-([a-z-]+)-v(.+)$ ]]; then
            EXT_ID="fx2dotnet-${BASH_REMATCH[1]}"
            VERSION="${BASH_REMATCH[2]}"
            EXT_DIR="${EXT_ID}"
            echo "extension-id=$EXT_ID" >> $GITHUB_OUTPUT
            echo "version=$VERSION" >> $GITHUB_OUTPUT
            echo "extension-dir=$EXT_DIR" >> $GITHUB_OUTPUT
          else
            echo "Invalid tag format: $TAG" >&2
            exit 1
          fi

  validate:
    needs: parse-tag
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate manifest
        run: |
          EXT_DIR="${{ needs.parse-tag.outputs.extension-dir }}"
          
          # Check manifest exists
          if [ ! -f "$EXT_DIR/extension.yml" ]; then
            echo "ERROR: extension.yml not found in $EXT_DIR"
            exit 1
          fi
          
          # Validate YAML syntax
          python3 -c "import yaml; yaml.safe_load(open('$EXT_DIR/extension.yml'))"
          
          # Validate manifest schema
          echo "Validating manifest schema..."
          # (Use spec-kit manifest validator if available)
          
          # Check all referenced files exist
          echo "Checking command files..."
          python3 << 'EOF'
          import yaml
          import os
          
          with open("$EXT_DIR/extension.yml") as f:
            manifest = yaml.safe_load(f)
          
          for cmd in manifest.get('provides', {}).get('commands', []):
            cmd_file = cmd['file']
            full_path = os.path.join("$EXT_DIR", cmd_file)
            if not os.path.exists(full_path):
              print(f"ERROR: Command file not found: {cmd_file}")
              exit(1)
          EOF

  build:
    needs: [parse-tag, validate]
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '10.0.x'
      
      - name: Restore dependencies
        run: dotnet restore src/fx2dotnet/fx2dotnet.csproj
        continue-on-error: true
      
      - name: Build MCP server
        run: dotnet build src/fx2dotnet/fx2dotnet.csproj -c Debug -o artifacts/bin/fx2dotnet/debug
        continue-on-error: true
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: mcp-binaries-${{ runner.os }}
          path: artifacts/bin/

  package:
    needs: [parse-tag, build]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          path: artifacts/
      
      - name: Create extension ZIP
        run: |
          EXT_ID="${{ needs.parse-tag.outputs.extension-id }}"
          VERSION="${{ needs.parse-tag.outputs.version }}"
          EXT_DIR="${{ needs.parse-tag.outputs.extension-dir }}"
          
          # Package extension with artifacts
          cd "$EXT_DIR"
          zip -r "../$EXT_ID-$VERSION.zip" . \
            -x "*.git*" \
            -x "*.tmp" \
            -x "*test*" \
            -x "*.local.yml"
          
          # Generate checksum
          sha256sum "../$EXT_ID-$VERSION.zip" > "../$EXT_ID-$VERSION.zip.sha256"
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: extension-package
          path: "fx2dotnet-*-*.zip*"

  publish:
    needs: [parse-tag, package]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download package artifacts
        uses: actions/download-artifact@v3
        with:
          name: extension-package
      
      - name: Create GitHub release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            fx2dotnet-*-*.zip
            fx2dotnet-*-*.zip.sha256
          body: |
            # ${{ needs.parse-tag.outputs.extension-id }} v${{ needs.parse-tag.outputs.version }}
            
            See CHANGELOG.md for details.
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  update-catalog:
    needs: [parse-tag, publish]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Generate catalog entry
        run: |
          EXT_ID="${{ needs.parse-tag.outputs.extension-id }}"
          VERSION="${{ needs.parse-tag.outputs.version }}"
          
          # Python script to generate/update catalog entry
          python3 << 'EOF'
          import json
          import datetime
          
          ext_id = "$EXT_ID"
          version = "$VERSION"
          download_url = f"https://github.com/${{ github.repository }}/releases/download/{ext_id}-v{version}/{ext_id}-{version}.zip"
          
          catalog = {}
          if os.path.exists("catalogs/catalog.json"):
            with open("catalogs/catalog.json") as f:
              catalog = json.load(f)
          
          # Load manifest
          with open(f"${{ needs.parse-tag.outputs.extension-dir }}/extension.yml") as f:
            manifest = yaml.safe_load(f)
          
          # Create catalog entry
          catalog["extensions"][ext_id] = {
            "id": ext_id,
            "name": manifest["extension"]["name"],
            "version": version,
            "description": manifest["extension"]["description"],
            "author": manifest["extension"].get("author", ""),
            "repository": manifest["extension"].get("repository", ""),
            "license": manifest["extension"].get("license", ""),
            "homepage": manifest["extension"].get("homepage", ""),
            "download_url": download_url,
            "requires": manifest["requires"],
            "provides": manifest["provides"],
            "tags": manifest.get("tags", []),
            "verified": True,
            "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat()
          }
          
          catalog["updated_at"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
          
          os.makedirs("catalogs", exist_ok=True)
          with open("catalogs/catalog.json", "w") as f:
            json.dump(catalog, f, indent=2)
          EOF
      
      - name: Commit catalog update
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Actions"
          git add catalogs/catalog.json
          git commit -m "chore: update catalog for ${{ needs.parse-tag.outputs.extension-id }} v${{ needs.parse-tag.outputs.version }}"
          git push
        continue-on-error: true
```

---

## Build Scripts

### build-mcp.sh (Compile MCP Server)

**Location**: `scripts/build-mcp.sh`

**Purpose**: Build the Swick.Mcp.Fx2dotnet MCP server and collect dependencies.

```bash
#!/bin/bash
# Build MCP server and stage artifacts for extension packaging

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"
BUILD_CONFIG="${BUILD_CONFIG:-Debug}"
OUTPUT_DIR="$REPO_ROOT/artifacts/bin/fx2dotnet/$BUILD_CONFIG"

echo "Building MCP server..."
echo "Config: $BUILD_CONFIG"
echo "Output: $OUTPUT_DIR"
echo ""

# Restore and build
cd "$REPO_ROOT/src/fx2dotnet"
dotnet restore
dotnet build -c "$BUILD_CONFIG" -o "$OUTPUT_DIR"

# Verify build
if [ ! -f "$OUTPUT_DIR/Swick.Mcp.Fx2dotnet.exe" ] && [ ! -f "$OUTPUT_DIR/Swick.Mcp.Fx2dotnet" ]; then
  echo "ERROR: MCP binary not found in output directory"
  exit 1
fi

echo ""
echo "✓ MCP server built successfully"
echo "Output directory: $OUTPUT_DIR"

# List artifacts
echo ""
echo "Artifacts:"
ls -lh "$OUTPUT_DIR"
```

### stage-artifacts.sh (Copy Binaries to Extensions)

**Location**: `scripts/stage-artifacts.sh`

**Purpose**: Copy compiled MCP server binaries to extension folders.

```bash
#!/bin/bash
# Stage MCP artifacts into extension directories

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"
BUILD_CONFIG="${BUILD_CONFIG:-Debug}"
ARTIFACTS_SRC="$REPO_ROOT/artifacts/bin/fx2dotnet/$BUILD_CONFIG"

# Extensions that use MCP tools
EXTENSIONS_WITH_MCP=(
  "fx2dotnet-assessment"
  "fx2dotnet-sdk-conversion"
  "fx2dotnet-package-compat"
)

echo "Staging MCP artifacts..."
echo "Source: $ARTIFACTS_SRC"
echo ""

if [ ! -d "$ARTIFACTS_SRC" ]; then
  echo "ERROR: Artifacts directory not found. Run build-mcp.sh first."
  exit 1
fi

for ext_id in "${EXTENSIONS_WITH_MCP[@]}"; do
  ext_dir="$REPO_ROOT/$ext_id"
  artifacts_dest="$ext_dir/artifacts/bin/fx2dotnet/$BUILD_CONFIG"
  
  echo "→ Staging to $ext_id..."
  
  mkdir -p "$artifacts_dest"
  cp -r "$ARTIFACTS_SRC"/* "$artifacts_dest/"
  
  echo "  ✓ Artifacts staged"
done

echo ""
echo "✓ All artifacts staged successfully"
```

---

## Manifest Templates

### extension.yml Template (Assessment Extension Example)

**Location**: `fx2dotnet-assessment/extension.yml`

```yaml
schema_version: "1.0"

extension:
  id: "fx2dotnet-assessment"
  name: "fx2dotnet Assessment"
  version: "1.0.0"
  description: "Discover .NET Framework projects, classify by type, and compute dependency layers"
  author: "YourOrg"
  repository: "https://github.com/yourorg/fx2dotnet-extensions"
  license: "MIT"
  homepage: "https://github.com/yourorg/fx2dotnet-extensions/tree/main/fx2dotnet-assessment"

requires:
  speckit_version: ">=0.2.0,<2.0.0"
  tools:
    - name: "Microsoft.GitHubCopilot.AppModernization.Mcp"
      version: ">=1.0.0"
      required: true
    - name: "Swick.Mcp.Fx2dotnet"
      version: ">=0.1.0"
      required: true
  commands:
    - "speckit.fx2dotnet-support-core.invoke-mcp"
    - "speckit.fx2dotnet-support-core.validate-project"

provides:
  commands:
    - name: "speckit.fx2dotnet-assessment.run"
      file: "commands/run.md"
      description: "Perform assessment on .NET Framework solution"
      aliases: ["speckit.fx2dotnet-assessment.analyze"]
    
    - name: "speckit.fx2dotnet-assessment.classify-projects"
      file: "commands/classify-projects.md"
      description: "Classify projects by type (web, console, library)"
    
    - name: "speckit.fx2dotnet-assessment.compute-layers"
      file: "commands/compute-layers.md"
      description: "Compute dependency layers for projects"

  config:
    - name: "fx2dotnet-assessment-config.yml"
      template: "fx2dotnet-assessment-config.template.yml"
      description: "Assessment configuration (logging, discovery settings)"
      required: false

hooks:
  after_tasks:
    command: "speckit.fx2dotnet-assessment.run"
    optional: true
    prompt: "Would you like to assess this .NET project?"
    condition: "config.enabled == true"

tags:
  - "dotnet"
  - "migration"
  - "modernization"
  - "analysis"
  - "discovery"

defaults:
  logging:
    level: "info"
  discovery:
    scan_depth: "unlimited"
    include_test_projects: false

config_schema:
  type: "object"
  properties:
    logging:
      type: "object"
      properties:
        level:
          type: "string"
          enum: ["debug", "info", "warning", "error"]
    discovery:
      type: "object"
      properties:
        scan_depth:
          type: "string"
```

---

## Extension Command Templates

### Command Markdown Template

**Location**: `fx2dotnet-assessment/commands/run.md`

```markdown
---
description: "Perform assessment on .NET Framework solution"
tools:
  - "Microsoft.GitHubCopilot.AppModernization.Mcp/get_scenarios"
  - "Swick.Mcp.Fx2dotnet/FindRecommendedPackageUpgrades"
scripts:
  sh: ../../scripts/bash/validate-solution.sh
  ps: ../../scripts/powershell/validate-solution.ps1
---

# Assessment Command

Analyze a .NET Framework solution to discover frameworks, projects, dependency layers, and package compatibility.

## Requirements

- Valid .sln or .slnx file path
- .NET Framework projects (4.0+)
- Read access to project files

## Steps

### 1. Validate Solution Path

$VALIDATE_SOLUTION_SCRIPT

### 2. Invoke Assessment MCP

Calls:
- `Microsoft.GitHubCopilot.AppModernization.Mcp/get_scenarios` — discover frameworks
- `Swick.Mcp.Fx2dotnet/FindRecommendedPackageUpgrades` — analyze packages

### 3. Generate State Files

Produces:
- `.fx2dotnet/analysis.md` — assessment findings (classifications, dependencies)
- `.fx2dotnet/package-updates.md` — compatibility analysis

## Configuration

Load from `.specify/extensions/fx2dotnet-assessment/fx2dotnet-assessment-config.yml`:

```yaml
logging:
  level: info                       # debug, info, warning, error
  output: console
discovery:
  scan_depth: unlimited             # shallow, limited, unlimited
  include_test_projects: false
```

## Output

Assessment state file (`.fx2dotnet/analysis.md`):

```markdown
# Assessment Report

## Project Inventory
- Total projects: 3
- Frameworks detected: .NET Framework 4.8, .NET Standard 2.0

## Dependency Layers
### Layer 1 (Leaf Projects)
- Business (class library)
- Data (EF6 library)

### Layer 2
- Presentation (web app, depends on Business, Data)

## Project Classifications
- Presentation: Web Host (ASP.NET Framework)
- Business: Library (SDK-style eligible)
- Data: Library (EF6 + custom migrations)
```

## Troubleshooting

**MCP tool timeout**: Increase timeout in config or run with `--verbose`

**Missing projects**: Check .sln file path and ensure all projects are referenced

**Package data unavailable**: NuGet.org connectivity required
```

---

## Validation & Testing Scripts

### validate-extension.sh (Local Validation)

**Location**: `scripts/validate-extension.sh`

**Purpose**: Validate an extension locally before release.

```bash
#!/bin/bash
# Validate a single extension for correctness

set -e

EXT_DIR="$1"

if [ -z "$EXT_DIR" ]; then
  echo "Usage: ./scripts/validate-extension.sh <extension-dir>"
  exit 1
fi

if [ ! -d "$EXT_DIR" ]; then
  echo "ERROR: Extension directory not found: $EXT_DIR"
  exit 1
fi

echo "Validating extension: $EXT_DIR"
echo ""

# Check manifest exists
if [ ! -f "$EXT_DIR/extension.yml" ]; then
  echo "✗ extension.yml not found"
  exit 1
fi
echo "✓ extension.yml found"

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('$EXT_DIR/extension.yml'))" 2>/dev/null || {
  echo "✗ Invalid YAML in extension.yml"
  exit 1
}
echo "✓ Valid YAML"

# Check command files exist
python3 << EOF
import yaml
import os

with open("$EXT_DIR/extension.yml") as f:
  manifest = yaml.safe_load(f)

ext_id = manifest['extension']['id']

for cmd in manifest['provides']['commands']:
  cmd_file = cmd['file']
  full_path = os.path.join("$EXT_DIR", cmd_file)
  if not os.path.exists(full_path):
    print(f"✗ Command file not found: {cmd_file}")
    exit(1)
  print(f"✓ Command file exists: {cmd_file}")

print("✓ All command files exist")
EOF

echo "✓ Extension is valid and ready for packaging"
```

### smoke-test.sh (Post-Install Testing)

**Location**: `scripts/smoke-test.sh`

**Purpose**: Test extension installation in a clean environment.

```bash
#!/bin/bash
# Run smoke tests on installed extensions

set -e

EXT_ID="$1"

if [ -z "$EXT_ID" ]; then
  echo "Usage: ./scripts/smoke-test.sh <extension-id>"
  exit 1
fi

echo "Running smoke tests for: $EXT_ID"
echo ""

# Test 1: Extension is installed
if ! specify extension list | grep -q "$EXT_ID"; then
  echo "✗ Extension not found in registry"
  exit 1
fi
echo "✓ Extension installed"

# Test 2: Config template exists
if [ ! -f ".specify/extensions/$EXT_ID/$EXT_ID-config.yml" ]; then
  echo "✗ Config file not created"
  exit 1
fi
echo "✓ Config file created"

# Test 3: Check artifacts if MCP-dependent
if grep -q "Microsoft.GitHubCopilot.AppModernization.Mcp" ".specify/extensions/$EXT_ID/extension.yml"; then
  if [ ! -d ".specify/extensions/$EXT_ID/artifacts" ]; then
    echo "⚠ Warning: MCP artifacts directory not found"
  else
    echo "✓ MCP artifacts present"
  fi
fi

echo ""
echo "✓ Smoke tests passed"
```

---

## Configuration Templates

### fx2dotnet-assessment-config.template.yml

**Location**: `fx2dotnet-assessment/fx2dotnet-assessment-config.template.yml`

```yaml
# fx2dotnet Assessment Configuration
# This file is created automatically on extension installation.
# Edit to customize assessment behavior.

# Logging configuration
logging:
  level: info                           # Options: debug, info, warning, error
  output: console                       # Options: console, file, none
  file_path: .fx2dotnet/assessment.log  # If output: file

# Project discovery settings
discovery:
  # Scan depth: how far to look for projects
  # - shallow: only find projects referenced in .sln/.slnx
  # - limited: also check parent/sibling directories
  # - unlimited: comprehensive filesystem scan
  scan_depth: unlimited
  
  # Include test projects in analysis?
  include_test_projects: false
  
  # Frameworks to specifically look for (empty = all)
  frameworks_to_detect: []
  
  # Minimum .NET Framework version (e.g., 4.6.1)
  min_framework_version: null

# Assessment output options
output:
  # Format for internal state files
  format: markdown                      # Options: markdown, json
  
  # Include dependency graph visualization?
  include_dependency_graph: true
  
  # Include package compatibility details?
  include_package_analysis: true

# Advanced settings
advanced:
  # MCP tool invocation timeout (seconds)
  mcp_timeout: 30
  
  # Parallel project processing?
  parallel_processing: false
  
  # Cache project metadata?
  use_cache: true
  cache_duration_hours: 24
```

---

## State Contract Specifications

### Canonical Identity Contract

- `projectId`: normalized relative `.csproj` path from the solution root.
- `projectDisplayName`: friendly project name for human readability.
- `projectStateFile`: collision-safe file name derived from display name plus hash when required.

All orchestration checkpoints, joins, and resume pointers must use `projectId` (never display name alone).

### .fx2dotnet/plan.md (Orchestrator State)

**Format**: Markdown with structured sections.

```markdown
# Migration Plan

**Solution**: path/to/Solution.sln
**Target Framework**: net8.0 (or net10.0)
**Created**: 2026-04-03T10:30:00Z
**Last Updated**: 2026-04-03T12:45:00Z

## Progress

| Phase | Status | Completed | Notes |
|-------|--------|-----------|-------|
| Assessment | ✓ Completed | 2026-04-03 10:45 | 3 projects, 2 layers identified |
| Planning | ✓ Completed | 2026-04-03 11:00 | SDK conversion order determined |
| SDK Conversion | ⏳ In Progress | — | Layer 1 (2 projects) complete |
| Package Compat | ⏸ Pending | — | Awaiting SDK conversion |
| Multitarget | ⏸ Pending | — | — |
| Web Migration | ⏸ Pending | — | Only if web host identified |
| Final Build | ⏸ Pending | — | — |

## Metadata

- `lastCompletedPhase`: sdk-normalization
- `packageCompatStatus`: not-started
- `multitargetStatus`: not-started
- `aspnetMigrationStatus`: not-started

## Per-Project Phase Matrix

| projectId | displayName | Assessment | Planning | SDK Conversion | Package Compat | Multitarget | Web Migration | Last Updated | Notes |
|-----------|-------------|------------|----------|----------------|----------------|-------------|---------------|--------------|-------|
| src/Business/Business.csproj | Business | completed | completed | completed | in-progress | not-started | skipped | 2026-04-03 12:45 | Waiting package validation |
| src/Data/Data.csproj | Data | completed | completed | blocked | not-started | not-started | skipped | 2026-04-03 12:30 | Blocked on SDK conversion error |
| src/Web/Presentation.csproj | Presentation | completed | completed | not-started | not-started | not-started | not-started | 2026-04-03 12:45 | Layer 2 pending Layer 1 |

## Project Summary

### Layer 1
- **Business.csproj** (EF6 library)
  - Status: SDK conversion complete
  - Target: net8.0
- **Data.csproj** (Library)
  - Status: Awaiting SDK conversion
  - Target: net8.0

### Layer 2
- **Presentation.csproj** (ASP.NET Framework web app)
  - Status: Awaiting all dependencies
  - Target: net8.0 + ASP.NET Core 8.0
  - Classification: Web Host
  - Notes: Requires web migration phase

## Decisions & Notes

- SDK conversion approach: Minimal changes, retain EF6
- Web migration: Use System.Web Adapters for initial deployment
- Package strategy: Small batches, build-test after each batch
```

### .fx2dotnet/analysis.md (Assessment Findings)

**Format**: Markdown with discovery results and classifications.

```markdown
# Assessment Report

**Date**: 2026-04-03  
**Solution**: path/to/Solution.sln  
**Assessed Projects**: 3  

## Project Inventory

| projectId | Project | Framework | Type | Location |
|-----------|---------|-----------|------|----------|
| src/Business/Business.csproj | Business.csproj | .NET Framework 4.8 | Class Library | src/Business/ |
| src/Data/Data.csproj | Data.csproj | .NET Framework 4.8 | Class Library | src/Data/ |
| src/Web/Presentation.csproj | Presentation.csproj | .NET Framework 4.8 | Web App | src/Web/ |

## Framework Inventory

- **.NET Framework 4.8**: 3 projects
- **.NET Standard 2.0**: 0 projects
- **.NET 6.0+**: 0 projects (targets for modernization)

## Dependency Layers

### Layer 1 (Leaves — no internal dependencies)
- Business.csproj
- Data.csproj

### Layer 2 (Depend on Layer 1)
- Presentation.csproj (depends on Business, Data)

## Project Classifications

### Business.csproj
- **Type**: Class Library
- **SDK-style Status**: Candidate (can convert)
- **Dependencies**: System, System.Core, NuGet packages
- **NuGet Packages**: 5 total (no EF6)

### Data.csproj
- **Type**: Class Library
- **SDK-style Status**: Candidate (can convert)
- **Dependencies**: Business (internal)
- **NuGet Packages**: EntityFramework 6.4.4, others
- **Special**: EF6 used; retain for Phase 5

### Presentation.csproj
- **Type**: Web Application (ASP.NET Framework)
- **SDK-style Status**: Not applicable (web host)
- **Routing**: Legacy route handlers (not attribute-based)
- **Special**: Requires separate web migration phase
- **Web Framework**: ASP.NET Framework 4.8
```

---

## Document Version History

- v1.0 — Implementation details extracted from main plan — April 3, 2026

---

## MCP Availability Continuity Runbook

This runbook defines how to maintain extension-suite functionality when the primary MCP dependency becomes unavailable.

### Continuity Modes

| Mode | Description | Activation Trigger | Exit Criteria |
|------|-------------|--------------------|---------------|
| Normal | Primary MCP source is reachable and healthy | Default mode | N/A |
| Fallback A | Internal mirror of same MCP package/version | 2 consecutive failed external pulls | External source stable for 3 consecutive successful pulls |
| Fallback B | Maintained compatibility fork of MCP tools | Source deprecated or breaking contract change | Official source restored with validated parity |
| Fallback C | Hybrid mode: reduced MCP + extension-native scripts/analyzers | Prolonged outage, no parity fork ready | Fallback B or Normal validated |
| Fallback D | Manual continuity mode with operator prompts | Emergency continuity requirement | Any automated fallback mode validated |

### Replacement Options and Technical Actions

#### Option A: Internal Mirror (Fastest)

1. Mirror the package and exact version to an internal feed.
2. Update extension MCP bootstrap/source configuration to point to internal feed.
3. Re-run deployment smoke tests and orchestrator dry run.

#### Option B: Compatibility Fork (Best Medium-Term)

1. Implement equivalent tool contract surface used by extension commands.
2. Keep tool names and response schema stable to avoid command changes.
3. Release the forked package to internal feed with pinned version.
4. Validate with phase-level regression tests and one end-to-end migration scenario.

#### Option C: Hybrid Replacement (Pragmatic Continuity)

1. Keep Swick.Mcp.Fx2dotnet for dependency layers/package recommendations.
2. Replace missing AppModernization operations with extension scripts and deterministic prompts.
3. Mark unsupported automation paths in diagnostics and release notes.

#### Option D: Manual Continuity Mode (Emergency)

1. Disable unavailable MCP calls via config feature flags.
2. Route workflow through assessment/planner/build-fix with manual confirmation checkpoints.
3. Record manual decisions in .fx2dotnet state files for auditability.

### Configuration Toggle Example

Add a continuity block in extension config templates for orchestrator and MCP-dependent extensions:

```yaml
continuity:
  mode: normal                  # normal | fallback-a | fallback-b | fallback-c | fallback-d
  mcp_source_priority:
    - external
    - internal-mirror
    - compatibility-fork
  allow_manual_mode: true
  emit_risk_banner: true
```

### Pipeline Guardrails

1. Add a pre-release MCP availability check job.
2. On failure, pipeline switches source priority and retries once.
3. If retry fails, tag release as degraded and publish with fallback mode metadata.

Example pseudo-steps:

```bash
# 1) Probe MCP package availability
./scripts/check-mcp-availability.sh --source external

# 2) If probe fails, switch to internal mirror
./scripts/switch-mcp-source.sh --target internal-mirror

# 3) Re-run install smoke tests
./scripts/smoke-test.sh fx2dotnet-assessment
./scripts/smoke-test.sh fx2dotnet-sdk-conversion
```

### Validation Matrix for Replacement Options

| Validation | A | B | C | D |
|------------|---|---|---|---|
| Extension install/uninstall | Required | Required | Required | Required |
| Assessment command success | Required | Required | Required | Required |
| SDK conversion parity check | Required | Required | Partial | Manual |
| Package compatibility output | Required | Required | Required | Required |
| Full orchestrator dry run | Required | Required | Required | Required |

### Release Communication Requirements

When fallback mode is active, release notes must include:

1. Active continuity mode and why it was triggered.
2. Known feature reductions (if any).
3. ETA and conditions to return to normal mode.

### Incident Ownership

| Role | Responsibility |
|------|----------------|
| Release Engineering | Pipeline source switching and artifact publication |
| Migration Platform Owner | Tool contract parity decisions and fallback selection |
| Extension Maintainers | Command-level validation and user-facing diagnostics |

