param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$ReportPath,
    [string]$HookMapPath,
    [string]$JsonPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "manifest-utils.ps1")

function Add-Issue {
    param(
        [Parameter(Mandatory)] $List,
        [Parameter(Mandatory)] [string]$Severity,
        [Parameter(Mandatory)] [string]$ExtensionId,
        [Parameter(Mandatory)] [string]$Message
    )

    $List.Add([pscustomobject]@{
            severity    = $Severity
            extensionId = $ExtensionId
            message     = $Message
        })
}

function Test-ForDependencyCycles {
    param([Parameter(Mandatory)] [hashtable]$DependencyGraph)

    $indegree = @{}
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $indegree.ContainsKey($node)) {
            $indegree[$node] = 0
        }

        foreach ($dependency in $DependencyGraph[$node]) {
            if (-not $indegree.ContainsKey($dependency)) {
                $indegree[$dependency] = 0
            }

            $indegree[$node] += 1
        }
    }

    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($pair in $indegree.GetEnumerator()) {
        if ($pair.Value -eq 0) {
            $queue.Enqueue($pair.Key)
        }
    }

    $visitedCount = 0
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        $visitedCount += 1

        foreach ($node in $DependencyGraph.Keys) {
            if ($DependencyGraph[$node] -contains $current) {
                $indegree[$node] -= 1
                if ($indegree[$node] -eq 0) {
                    $queue.Enqueue($node)
                }
            }
        }
    }

    if ($visitedCount -eq $indegree.Count) {
        return @()
    }

    return @($indegree.GetEnumerator() | Where-Object Value -gt 0 | Sort-Object Name | ForEach-Object Name)
}

$extensionDirs = @(Get-ChildItem -Path $RepoRoot -Directory |
    Where-Object {
        $_.Name -like "fx2dotnet-*" -and (Test-Path (Join-Path $_.FullName "extension.yml"))
    } |
    Sort-Object Name)

if ($extensionDirs.Count -eq 0) {
    throw "No extension manifests were found beneath $RepoRoot."
}

$issues = [System.Collections.Generic.List[object]]::new()
$hookEntries = [System.Collections.Generic.List[object]]::new()
$extensionSummaries = [System.Collections.Generic.List[object]]::new()
$providerByCommand = @{}
$extensionIdToManifest = @{}

foreach ($extensionDir in $extensionDirs) {
    $manifestPath = Join-Path $extensionDir.FullName "extension.yml"
    $manifest = Read-ExtensionManifest -Path $manifestPath
    $extensionId = [string]$manifest.extension.id

    if ([string]::IsNullOrWhiteSpace($extensionId)) {
        Add-Issue -List $issues -Severity "error" -ExtensionId $extensionDir.Name -Message "Manifest is missing extension.id."
        continue
    }

    $extensionIdToManifest[$extensionId] = [pscustomobject]@{
        directory = $extensionDir.FullName
        manifest  = $manifest
    }

    if ([string]$manifest.schema_version -ne "1.0") {
        Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "Unsupported schema_version '$($manifest.schema_version)'."
    }

    $providedCommands = @($manifest.provides.commands)
    if ($providedCommands.Count -eq 0) {
        Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "Manifest does not provide any commands."
    }

    foreach ($command in $providedCommands) {
        $commandName = [string]$command.name
        $commandFile = [string]$command.file

        if ([string]::IsNullOrWhiteSpace($commandName)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "A provided command is missing its name."
            continue
        }

        if ($providerByCommand.ContainsKey($commandName)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "Command naming conflict for '$commandName'. Already provided by '$($providerByCommand[$commandName])'."
        }
        else {
            $providerByCommand[$commandName] = $extensionId
        }

        if ([string]::IsNullOrWhiteSpace($commandFile)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "Command '$commandName' is missing its file path."
            continue
        }

        $commandPath = Join-Path $extensionDir.FullName $commandFile
        if (-not (Test-Path $commandPath)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "Command file '$commandFile' does not exist."
        }
    }

    $configEntries = @($manifest.provides.config)
    foreach ($configEntry in $configEntries) {
        $templatePath = [string]$configEntry.template
        if ([string]::IsNullOrWhiteSpace($templatePath)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "A config entry is missing its template path."
            continue
        }

        $resolvedTemplatePath = Join-Path $extensionDir.FullName $templatePath
        if (-not (Test-Path $resolvedTemplatePath)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionId -Message "Config template '$templatePath' does not exist."
        }
    }

    if ($null -ne $manifest.hooks) {
        foreach ($hookProperty in $manifest.hooks.GetEnumerator()) {
            $hookEntries.Add([pscustomobject]@{
                    extensionId = $extensionId
                    hook        = $hookProperty.Key
                    command     = [string]$hookProperty.Value.command
                    optional    = [bool]$hookProperty.Value.optional
                    prompt      = [string]$hookProperty.Value.prompt
                })
        }
    }

    $requiredCommands = @($manifest.requires.commands)
    $requiredTools = @($manifest.requires.tools)
    $extensionSummaries.Add([pscustomobject]@{
            extensionId        = $extensionId
            manifestPath       = $manifestPath.Substring($RepoRoot.Length + 1).Replace("\", "/")
            commandCount       = $providedCommands.Count
            configCount        = $configEntries.Count
            requiredCommandIds = @($requiredCommands)
            requiredToolCount  = $requiredTools.Count
            hookCount          = @($hookEntries | Where-Object extensionId -eq $extensionId).Count
        })
}

$dependencyGraph = @{}
foreach ($extensionSummary in $extensionSummaries) {
    $providers = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($requiredCommandId in $extensionSummary.requiredCommandIds) {
        if (-not $providerByCommand.ContainsKey($requiredCommandId)) {
            Add-Issue -List $issues -Severity "error" -ExtensionId $extensionSummary.extensionId -Message "Requires unknown command '$requiredCommandId'."
            continue
        }

        [void]$providers.Add($providerByCommand[$requiredCommandId])
    }

    $dependencyGraph[$extensionSummary.extensionId] = @($providers | Sort-Object)
}

$cyclicExtensions = @(Test-ForDependencyCycles -DependencyGraph $dependencyGraph)
if ($cyclicExtensions.Count -gt 0) {
    Add-Issue -List $issues -Severity "error" -ExtensionId "suite" -Message "Circular dependency detected across: $($cyclicExtensions -join ', ')"
}

$summary = [pscustomobject]@{
    generatedAtUtc   = [DateTime]::UtcNow.ToString("o")
    repoRoot         = $RepoRoot
    manifestCount    = $extensionSummaries.Count
    providedCommands = $providerByCommand.Count
    hooks            = $hookEntries.Count
    extensions       = @($extensionSummaries)
    dependencyGraph  = $dependencyGraph
    hooksMap         = @($hookEntries)
    issues           = @($issues)
}

if ($JsonPath) {
    $jsonDirectory = Split-Path -Path $JsonPath -Parent
    if ($jsonDirectory) {
        New-Item -Path $jsonDirectory -ItemType Directory -Force | Out-Null
    }

    $summary | ConvertTo-Json -Depth 20 | Set-Content -Path $JsonPath -Encoding utf8
}

if ($ReportPath) {
    $reportDirectory = Split-Path -Path $ReportPath -Parent
    if ($reportDirectory) {
        New-Item -Path $reportDirectory -ItemType Directory -Force | Out-Null
    }

    $reportLines = [System.Collections.Generic.List[string]]::new()
    $reportLines.Add("# Manifest Validation Report")
    $reportLines.Add("")
    $reportLines.Add("Generated: $($summary.generatedAtUtc)")
    $reportLines.Add("")
    $reportLines.Add("## Summary")
    $reportLines.Add("")
    $reportLines.Add("| Metric | Value |")
    $reportLines.Add("|---|---:|")
    $reportLines.Add("| Extension manifests | $($summary.manifestCount) |")
    $reportLines.Add("| Provided commands | $($summary.providedCommands) |")
    $reportLines.Add("| Hook registrations | $($summary.hooks) |")
    $reportLines.Add("| Validation status | $(if ($summary.issues.Count -eq 0) { 'PASS' } else { 'FAIL' }) |")
    $reportLines.Add("")
    $reportLines.Add("## Extension Matrix")
    $reportLines.Add("")
    $reportLines.Add("| Extension | Commands | Config Templates | Required Commands | Required Tools | Hooks |")
    $reportLines.Add("|---|---:|---:|---:|---:|---:|")
    foreach ($extensionSummary in $extensionSummaries | Sort-Object extensionId) {
        $reportLines.Add("| $($extensionSummary.extensionId) | $($extensionSummary.commandCount) | $($extensionSummary.configCount) | $($extensionSummary.requiredCommandIds.Count) | $($extensionSummary.requiredToolCount) | $($extensionSummary.hookCount) |")
    }
    $reportLines.Add("")
    $reportLines.Add("## Dependency Review")
    $reportLines.Add("")
    foreach ($extensionSummary in $extensionSummaries | Sort-Object extensionId) {
        $dependencies = @($dependencyGraph[$extensionSummary.extensionId])
        if ($dependencies.Count -eq 0) {
            $reportLines.Add("- $($extensionSummary.extensionId): no cross-extension command dependencies")
        }
        else {
            $reportLines.Add("- $($extensionSummary.extensionId): depends on $($dependencies -join ', ')")
        }
    }
    $reportLines.Add("")
    $reportLines.Add("## Findings")
    $reportLines.Add("")
    if ($summary.issues.Count -eq 0) {
        $reportLines.Add("- No manifest, command-file, dependency, or hook coordination issues were detected.")
    }
    else {
        foreach ($issue in $summary.issues) {
            $reportLines.Add("- [$($issue.severity.ToUpperInvariant())] $($issue.extensionId): $($issue.message)")
        }
    }

    $reportLines | Set-Content -Path $ReportPath -Encoding utf8
}

if ($HookMapPath) {
    $hookMapDirectory = Split-Path -Path $HookMapPath -Parent
    if ($hookMapDirectory) {
        New-Item -Path $hookMapDirectory -ItemType Directory -Force | Out-Null
    }

    $hookLines = [System.Collections.Generic.List[string]]::new()
    $hookLines.Add("# Hook Coordination Map")
    $hookLines.Add("")
    $hookLines.Add("Generated: $($summary.generatedAtUtc)")
    $hookLines.Add("")
    if ($hookEntries.Count -eq 0) {
        $hookLines.Add("The extension suite currently registers no hooks.")
    }
    else {
        $hookLines.Add("| Extension | Hook | Command | Optional | Prompt |")
        $hookLines.Add("|---|---|---|---|---|")
        foreach ($hookEntry in $hookEntries | Sort-Object extensionId, hook) {
            $hookLines.Add("| $($hookEntry.extensionId) | $($hookEntry.hook) | $($hookEntry.command) | $($hookEntry.optional) | $($hookEntry.prompt) |")
        }
        $hookLines.Add("")
        $hookLines.Add("Only bootstrap assessment uses a hook. Phase-to-phase execution remains orchestrator-driven to preserve deterministic sequencing.")
    }

    $hookLines | Set-Content -Path $HookMapPath -Encoding utf8
}

if ($summary.issues.Count -gt 0) {
    $summary.issues | ForEach-Object {
        Write-Error "$($_.extensionId): $($_.message)"
    }

    exit 1
}

Write-Host "Validated $($summary.manifestCount) extension manifests, $($summary.providedCommands) provided commands, and $($summary.hooks) hooks."
