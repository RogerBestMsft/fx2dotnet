# .NET Project Type Detector

This extension wraps the read-only project classification helper used by the assessment workflow.

## Command

- Command: `speckit.fx-project-detector.classify`
- Argument hint: provide a project file path.
- Backing file: `commands/classify.md`

## Intended Usage

This extension is designed for orchestrator delegation, not direct manual use. The assessment phase uses it to classify projects in parallel.

## Output

The command returns project type evidence, confidence, and SDK-style status so assessment can build a complete migration inventory.

## Repository

Parent plugin repository: https://github.com/RogerBestMSFT/fx2dotnet