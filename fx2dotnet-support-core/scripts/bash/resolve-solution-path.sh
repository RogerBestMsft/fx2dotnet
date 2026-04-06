#!/bin/bash
set -e

INPUT_PATH="$1"

if [ -z "$INPUT_PATH" ]; then
  echo "ERROR: solution path or directory is required" >&2
  exit 1
fi

if [ -f "$INPUT_PATH" ]; then
  case "$INPUT_PATH" in
    *.sln|*.slnx)
      realpath "$INPUT_PATH"
      exit 0
      ;;
    *)
      echo "ERROR: unsupported file type: $INPUT_PATH" >&2
      exit 1
      ;;
  esac
fi

if [ -d "$INPUT_PATH" ]; then
  SOLUTION=$(find "$INPUT_PATH" -maxdepth 2 \( -name "*.sln" -o -name "*.slnx" \) | head -n 1)
  if [ -z "$SOLUTION" ]; then
    echo "ERROR: no .sln or .slnx found under $INPUT_PATH" >&2
    exit 1
  fi
  realpath "$SOLUTION"
  exit 0
fi

echo "ERROR: path not found: $INPUT_PATH" >&2
exit 1
