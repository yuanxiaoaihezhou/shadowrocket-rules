#!/bin/bash
# sync_modules.sh
# Downloads modules listed in module_list.txt and localizes all external
# script-path and icon resources into this repository.

set -euo pipefail

MODULE_LIST="module_list.txt"
MODULES_DIR="modules"
SCRIPTS_DIR="modules/scripts"
ICONS_DIR="modules/icons"

# Use the GITHUB_REPOSITORY env var (available in GitHub Actions) so this
# works correctly even in forks.
GITHUB_REPO="${GITHUB_REPOSITORY:-yuanxiaoaihezhou/shadowrocket-rules}"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"

mkdir -p "$MODULES_DIR" "$SCRIPTS_DIR" "$ICONS_DIR"

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
  python3 download_with_browser.py "$url" "$tmp_file"

  # Localize the module icon (#!icon=): download and replace with local URL.
  while IFS= read -r icon_url; do
    [[ -z "$icon_url" ]] && continue
    icon_filename=$(basename "$icon_url" | sed 's/[?#].*//')
    echo "  Downloading icon: $icon_filename"
    # Use curl for binary assets (icons are images; the Playwright-based
    # downloader only captures text and would corrupt binary files).
    if ! curl -fsL --max-time 30 -o "${ICONS_DIR}/${icon_filename}" "$icon_url"; then
      echo "  WARNING: Failed to download icon $icon_filename from $icon_url" >&2
      continue
    fi
    local_icon_url="${RAW_BASE}/modules/icons/${icon_filename}"
    # Use Python for the URL replacement to avoid sed special-character issues.
    python3 - "$tmp_file" "$icon_url" "$local_icon_url" <<'PYEOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    content = f.read()
with open(path, "w", encoding="utf-8") as f:
    f.write(content.replace(old, new))
PYEOF
  done < <(grep -oE '#!icon=https?://[^[:space:]]+' "$tmp_file" | sed 's/#!icon=//' | sort -u)

  # Extract all script-path URLs from the [Script] section and download them
  while IFS= read -r script_url; do
    [[ -z "$script_url" ]] && continue
    # Strip query-string parameters from the filename to get a clean local name.
    # e.g. "goofish.js?token=209863" -> "goofish.js"
    script_filename=$(basename "$script_url" | sed 's/[?#].*//')
    echo "  Downloading script: $script_filename"
    python3 download_with_browser.py "$script_url" "${SCRIPTS_DIR}/${script_filename}"
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
