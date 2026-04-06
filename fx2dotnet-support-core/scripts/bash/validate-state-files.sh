#!/bin/bash
set -e

STATE_ROOT="$1"

if [ -z "$STATE_ROOT" ]; then
  echo "ERROR: state root path required" >&2
  exit 1
fi

for file in "plan.md" "analysis.md" "package-updates.md"; do
  if [ ! -f "$STATE_ROOT/$file" ]; then
    echo "MISSING: $STATE_ROOT/$file"
  fi
done
