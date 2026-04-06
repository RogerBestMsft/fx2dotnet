#!/bin/bash
set -e

PROJECT_PATH="$1"

if [ -z "$PROJECT_PATH" ] || [ ! -f "$PROJECT_PATH" ]; then
  echo "ERROR: valid project path required" >&2
  exit 1
fi

echo "Project: $PROJECT_PATH"
grep -E "<(OutputType|TargetFramework|TargetFrameworks|ProjectReference|PackageReference|Reference)" "$PROJECT_PATH" || true
