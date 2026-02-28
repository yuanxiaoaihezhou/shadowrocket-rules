#!/bin/bash
# sync_modules.sh
# Downloads modules listed in module_list.txt and localizes all external
# script-path resources into this repository.

set -euo pipefail

MODULE_LIST="module_list.txt"
MODULES_DIR="modules"
SCRIPTS_DIR="modules/scripts"

# Use the GITHUB_REPOSITORY env var (available in GitHub Actions) so this
# works correctly even in forks.
GITHUB_REPO="${GITHUB_REPOSITORY:-yuanxiaoaihezhou/shadowrocket-rules}"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"

mkdir -p "$MODULES_DIR" "$SCRIPTS_DIR"

if [ ! -f "$MODULE_LIST" ]; then
  echo "No module_list.txt found, skipping module sync."
  exit 0
fi

while IFS= read -r url || [ -n "$url" ]; do
  # Skip empty lines and comments
  [[ -z "$url" || "$url" == \#* ]] && continue

  module_filename=$(basename "$url")
  echo "Processing module: $module_filename from $url"

  tmp_file=$(mktemp)
  curl --fail -sSL --retry 3 --retry-delay 2 \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    -o "$tmp_file" "$url"

  # Extract all script-path URLs from the [Script] section and download them
  while IFS= read -r script_url; do
    [[ -z "$script_url" ]] && continue
    script_filename=$(basename "$script_url")
    echo "  Downloading script: $script_filename"
    curl --fail -sSL --retry 3 --retry-delay 2 \
      -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
      -o "${SCRIPTS_DIR}/${script_filename}" "$script_url"
    local_url="${RAW_BASE}/modules/scripts/${script_filename}"
    # Replace the remote URL with the local GitHub raw URL in the module file.
    # Use a temp file for the replacement to avoid sed -i portability issues.
    sed "s|${script_url}|${local_url}|g" "$tmp_file" > "${tmp_file}.new" && mv "${tmp_file}.new" "$tmp_file"
  done < <(grep -oE 'script-path=https?://[^,[:space:]]+' "$tmp_file" | sed 's/script-path=//' | sort -u)

  cp "$tmp_file" "${MODULES_DIR}/${module_filename}"
  rm -f "$tmp_file"
  echo "  Saved localized module: ${MODULES_DIR}/${module_filename}"
done < "$MODULE_LIST"

echo "Module sync complete."
