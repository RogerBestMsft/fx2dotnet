#!/bin/bash
set -e

SOLUTION_PATH="$1"

if [ -z "$SOLUTION_PATH" ] || [ ! -f "$SOLUTION_PATH" ]; then
  echo "ERROR: valid .sln or .slnx path required" >&2
  exit 1
fi

case "$SOLUTION_PATH" in
  *.sln|*.slnx) exit 0 ;;
  *) echo "ERROR: unsupported solution type: $SOLUTION_PATH" >&2; exit 1 ;;
esac
