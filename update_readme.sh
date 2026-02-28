#!/bin/bash
# update_readme.sh
# Scans the rules/ and modules/ directories and updates README.md with
# subscription URLs between the designated marker comments.

set -euo pipefail

README="README.md"
GITHUB_REPO="${GITHUB_REPOSITORY:-yuanxiaoaihezhou/shadowrocket-rules}"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"

RULES_TMP=$(mktemp)
MODULES_TMP=$(mktemp)
trap 'rm -f "$RULES_TMP" "$MODULES_TMP"' EXIT

# Build the rules table content into a temp file
if [ -d "rules" ] && compgen -G "rules/*" > /dev/null 2>&1; then
  printf '| 规则名称 | 订阅地址 |\n|----------|----------|\n' > "$RULES_TMP"
  for f in rules/*; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")
    printf '| %s | `%s/rules/%s` |\n' "$filename" "$RAW_BASE" "$filename" >> "$RULES_TMP"
  done
else
  printf '_暂无规则文件_\n' > "$RULES_TMP"
fi

# Build the modules table content into a temp file
if [ -d "modules" ] && compgen -G "modules/*.module" > /dev/null 2>&1; then
  printf '| 模块名称 | 订阅地址 |\n|----------|----------|\n' > "$MODULES_TMP"
  for f in modules/*.module; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")
    printf '| %s | `%s/modules/%s` |\n' "$filename" "$RAW_BASE" "$filename" >> "$MODULES_TMP"
  done
else
  printf '_暂无模块文件_\n' > "$MODULES_TMP"
fi

# Replace content between markers in README using Python
python3 - "$README" "$RULES_TMP" "$MODULES_TMP" <<'PYEOF'
import re, sys

readme_path, rules_path, modules_path = sys.argv[1], sys.argv[2], sys.argv[3]

with open(readme_path, "r", encoding="utf-8") as fh:
    content = fh.read()

with open(rules_path, "r", encoding="utf-8") as fh:
    rules_content = fh.read()

with open(modules_path, "r", encoding="utf-8") as fh:
    modules_content = fh.read()

def replace_block(text, marker, inner):
    start = f"<!-- {marker}_START -->"
    end = f"<!-- {marker}_END -->"
    replacement = f"{start}\n{inner}{end}"
    return re.sub(
        re.escape(start) + r".*?" + re.escape(end),
        replacement,
        text,
        flags=re.DOTALL,
    )

content = replace_block(content, "RULES_TABLE", rules_content)
content = replace_block(content, "MODULES_TABLE", modules_content)

with open(readme_path, "w", encoding="utf-8") as fh:
    fh.write(content)

print("README.md updated successfully.")
PYEOF
