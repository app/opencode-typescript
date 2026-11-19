#!/usr/bin/env bash
#
# Check the documentation examples.
#
# The consumer docs (README.md and docs/) describe the host side: every fenced
# bash/sh block must parse and must not call tools that exist only inside the
# image. The API flow is canonical: AGENTS.md and docs/api.md must carry the
# same block between the `canonical: api-flow` markers.
#
# Run by the Build workflow; also useful locally.

set -euo pipefail

cd "$(dirname "$0")/.."

status=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Split the fenced bash/sh blocks of a Markdown file into $prefix.<n>.sh files.
extract_blocks() {
  local file="$1" prefix="$2"
  awk -v prefix="$prefix" '
    /^```(bash|sh)[[:space:]]*$/ { inside = 1; n++; next }
    /^```[[:space:]]*$/ { inside = 0; next }
    inside { print > (prefix "." n ".sh") }
  ' "$file"
}

# Print everything between the canonical API flow markers.
extract_canonical() {
  awk '
    /<!-- canonical: api-flow -->/ { inside = 1; next }
    /<!-- \/canonical: api-flow -->/ { inside = 0; next }
    inside
  ' "$1"
}

for file in README.md docs/*.md; do
  prefix="$tmp/$(basename "$file" .md)"
  extract_blocks "$file" "$prefix"
  for block in "$prefix".*.sh; do
    [[ -e "$block" ]] || continue
    if ! bash -n "$block"; then
      echo "error: $file has a block that does not parse ($block)" >&2
      status=1
    fi
    if grep -nE '^[[:space:]]*(cd[[:space:]]+/home/opencode|mise([[:space:]]|$)|uv([[:space:]]|$)|uvx([[:space:]]|$)|apk([[:space:]]|$)|sudo[[:space:]]+apk)' "$block"; then
      echo "error: $file contains a container-only command; move it to config/opencode/docs/" >&2
      status=1
    fi
  done
done

if ! diff -u <(extract_canonical AGENTS.md) <(extract_canonical docs/api.md); then
  echo "error: the canonical API flow differs between AGENTS.md and docs/api.md" >&2
  status=1
fi

if ((status)); then
  exit 1
fi
echo "Documentation examples are consistent."
