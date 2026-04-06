#!/usr/bin/env bash
set -euo pipefail

# Bump the version in all spec-kit extension.yml files
# Usage: scripts/bump-version.sh 0.2.0

if [ $# -ne 1 ]; then
  echo "Usage: $0 <new-version>" >&2
  exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_KIT="$SCRIPT_DIR/.."

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
  yml="$SPEC_KIT/$ext/extension.yml"
  if [ ! -f "$yml" ]; then
    echo "WARNING: $yml not found" >&2
    continue
  fi
  sed -i "s/version: .*/version: \"$VERSION\"/" "$yml"
  echo "  $ext -> $VERSION"
done

echo "Bumped all extensions to $VERSION"
