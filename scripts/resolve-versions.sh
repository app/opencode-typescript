#!/usr/bin/env bash
#
# Resolve the current upstream versions used by the image build.
#
# Prints KEY=VALUE lines to stdout:
#   opencode=<semver>  latest stable release of the upstream OpenCode image
#   node=<semver>      current Node LTS from nodejs.org
#
# Used by the GitHub Actions workflow. The update-pins job compares the
# result against versions.json in the repository and opens a pull request
# when they differ.

set -euo pipefail

UPSTREAM_REPO="anomalyco/opencode"

# Fetch the newest stable tag of the upstream image. The GHCR tag list is
# paginated, so follow the Link header until the last page. Prereleases and
# moving tags (latest, snapshot-*) are filtered out.
latest_opencode() {
  local repo="${UPSTREAM_REPO}" token hdr url last body tags=""
  token="$(curl -fsS \
    "https://ghcr.io/token?scope=repository:${repo}:pull&service=ghcr.io" \
    | jq -r .token)"
  hdr="$(mktemp)"
  url="https://ghcr.io/v2/${repo}/tags/list?n=1000"
  while :; do
    body="$(curl -fsS -D "$hdr" -H "Authorization: Bearer ${token}" "$url")"
    tags+="$(jq -r '.tags[]?' <<<"$body")"$'\n'
    last="$(sed -nE 's/.*[?&]last=([^&>]*).*/\1/p' "$hdr" \
      | awk 'NR == 1 { print; exit }')"
    [[ -n "$last" ]] || break
    url="https://ghcr.io/v2/${repo}/tags/list?n=1000&last=${last}"
  done
  rm -f "$hdr"
  printf '%s\n' "$tags" \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1 || true
}

OC="$(latest_opencode)"
# index.json carries the "v" prefix (v26.13.1); strip it for mise and tags.
NODE="$(curl -fsSL https://nodejs.org/dist/index.json \
  | jq -r '[.[] | select(.lts != null and .lts != false)] | .[0].version | sub("^v"; "")')"

if [[ ! "$OC" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Could not resolve the latest OpenCode version." >&2
  exit 1
fi
if [[ ! "$NODE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Could not resolve the current Node LTS version." >&2
  exit 1
fi

echo "opencode=${OC}"
echo "node=${NODE}"
