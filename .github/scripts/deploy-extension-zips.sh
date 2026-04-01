#!/usr/bin/env bash
set -euo pipefail

zip_dir="${1:-artifacts/extensions}"

if ! command -v specify >/dev/null 2>&1; then
  echo "The 'specify' CLI is not installed or not on PATH."
  exit 1
fi

shopt -s nullglob
zip_files=("${zip_dir}"/*.zip)

if [ ${#zip_files[@]} -eq 0 ]; then
  echo "No zip files found in ${zip_dir}"
  exit 1
fi

for zip_file in "${zip_files[@]}"; do
  file_name="$(basename "${zip_file}")"
  extension_name="${file_name%.zip}"

  echo "Deploying ${extension_name} from ${zip_file}"
  specify extension add "${extension_name}" --from "${zip_file}"
done

echo "Deployed ${#zip_files[@]} extension bundle(s)."
