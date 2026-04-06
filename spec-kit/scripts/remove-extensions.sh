#!/usr/bin/env bash
set -euo pipefail

# Remove all spec-kit fx-to-dotnet extensions from the local Spec Kit installation.

EXTENSIONS=(
  fx-to-dotnet
  fx-to-dotnet-assess
  fx-to-dotnet-plan
  fx-to-dotnet-sdk-convert
  fx-to-dotnet-build-fix
  fx-to-dotnet-package-compat
  fx-to-dotnet-multitarget
  fx-to-dotnet-web-migrate
  fx-to-dotnet-detect-project
  fx-to-dotnet-route-inventory
  fx-to-dotnet-policies
)

for ext in "${EXTENSIONS[@]}"; do
  echo "Removing $ext..."
  if ! specify extension remove "$ext" 2>/dev/null; then
    echo "  $ext was not installed, skipping"
  fi
done

echo ""
echo "Done. All fx-to-dotnet extensions removed."
