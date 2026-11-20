#!/usr/bin/env bash
#
# Smoke test a published image.
#
# Assert the image default stays the interactive TUI, start the server
# explicitly, wait for GET /api/info with Basic auth, check the reported
# version, and verify the agent guides are baked in.
#
# Usage: smoke-test.sh <amd64|arm64> <image>
#
# The arm64 run is emulated with QEMU on the amd64 CI runner, so its wait
# window is longer. Run by the Build workflow.

set -euo pipefail

usage() {
  echo "usage: smoke-test.sh <amd64|arm64> <image>" >&2
  exit 2
}
[[ $# -eq 2 ]] || usage
arch="$1"
image="$2"
case "$arch" in
amd64) wait_rounds=30 ;;
arm64) wait_rounds=90 ;;
*) usage ;;
esac
: "${OPENCODE_VERSION:?OPENCODE_VERSION is required}"
: "${SMOKE_PASSWORD:?SMOKE_PASSWORD is required}"

name="opencode-smoke-${arch}"

# Pull once (the runner's own architecture) for the CMD check; the arm64
# variant is pulled implicitly by `docker run --platform` below.
docker pull "$image"
image_cmd="$(docker inspect --format '{{join .Config.Cmd " "}}' "$image")"
if [[ "$image_cmd" != "opencode" ]]; then
  echo "Unexpected image default CMD: $image_cmd" >&2
  exit 1
fi

docker run -d --name "$name" --platform "linux/${arch}" \
  -e OPENCODE_PASSWORD="$SMOKE_PASSWORD" \
  "$image" opencode serve --hostname 0.0.0.0 --port 4096
trap 'docker rm -f "$name" >/dev/null' EXIT

up=""
for _ in $(seq 1 "$wait_rounds"); do
  if docker exec "$name" curl -fsS -u "opencode:$SMOKE_PASSWORD" http://localhost:4096/api/info >/dev/null 2>&1; then
    up="yes"
    break
  fi
  sleep 2
done
[[ "$up" == "yes" ]] || {
  echo "The server did not come up." >&2
  exit 1
}

info="$(docker exec "$name" curl -fsS -u "opencode:$SMOKE_PASSWORD" http://localhost:4096/api/info)"
echo "$info"
version="$(jq -r '.version // empty' <<<"$info")"
if [[ -n "$version" && "$version" != "$OPENCODE_VERSION" ]]; then
  echo "Server version mismatch: expected $OPENCODE_VERSION, got $version." >&2
  exit 1
fi

# The agent guides must be baked with the configuration.
for guide in workspace typescript troubleshooting; do
  docker exec "$name" test -f "/home/opencode/.config/opencode/docs/${guide}.md"
done
echo "agent guides baked (linux/${arch})"
