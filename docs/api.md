# Access

How the three kinds of users reach the agent. OpenCode lives only inside the
container; nothing is installed on the host.

## TUI

The image default. From the project directory:

```bash
podman run -it --rm --name "opencode-$$" --userns=keep-id:uid=1000,gid=1000 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --detach-keys="ctrl-],ctrl-q" \
  ghcr.io/app/opencode-typescript:latest
```

See [Usage](usage.md#open-the-tui-default) for the mount layout (Docker:
the same with `--user` instead of `--userns`). The TUI talks to the local
process inside
the container and needs no password.

## Web UI

The web UI is served by the [server mode](usage.md#start-the-server-web-ui-http-api).
To sign in, create a pairing link from inside the running container (its
name is in [Usage](usage.md#logs)):

Podman:

```bash
name="$(podman ps --format '{{.Names}}' | grep '^opencode-' | head -n1)"
podman exec -it --detach-keys="ctrl-],ctrl-q" "$name" opencode pair
```

Docker:

```bash
name="$(docker ps --format '{{.Names}}' | grep '^opencode-' | head -n1)"
docker exec -it --detach-keys="ctrl-],ctrl-q" "$name" opencode pair
```

Open the printed link in a browser (the port must be published,
`-p 4096:4096`). Links work once and expire in 5 minutes; sessions last
30 days. Changing the server password signs every session out. Over SSH,
forward the server port and open the link locally.

## Authentication

Server mode is password-protected. Set `OPENCODE_PASSWORD` in the env file to
use a fixed password; when it is empty, the server generates a random one and
prints it to the container log on start. HTTP clients use Basic auth: the
username is always `opencode`, and only the password can be changed.

## HTTP API (agents)

Start the server explicitly with a password (see
[Usage](usage.md#start-the-server-web-ui-http-api)), export the same password in
the shell, and use the REST API (`curl` and `jq` are assumed):

<!-- canonical: api-flow -->

```bash
BASE=http://localhost:4096
AUTH="opencode:$OPENCODE_PASSWORD"

# Server info (also a good health check)
curl -fsS -u "$AUTH" "$BASE/api/info"

# Create a session
SESSION=$(curl -fsS -u "$AUTH" -X POST "$BASE/api/session" | jq -r .id)

# Send a prompt
curl -fsS -u "$AUTH" -X POST "$BASE/api/session/$SESSION/prompt" \
  -H "Content-Type: application/json" \
  -d '{"parts": [{"type": "text", "text": "Summarize this repository"}]}'

# Subscribe to server events
curl -fsS -u "$AUTH" -N "$BASE/api/event"
```

<!-- /canonical: api-flow -->

- The OpenAPI 3.1 document of a running server is served at
  `http://localhost:4096/openapi.json`; the published reference lives at
  <https://opencode.ai/docs/openapi.json>.
- The generated TypeScript client is `@opencode/client` (Promise-based
  resource clients and async iterables for streaming endpoints).
- Permission requests: the baked configuration allows `edit`, `shell` and
  `webfetch` autonomously; for `ask` outcomes, clients reply through
  `POST /api/session/{sessionID}/permission/{requestID}/reply`
  (`once`, `always`, `reject`).
- See <https://opencode.ai/docs/api> for the full endpoint reference.

## Pairing from the server side

`POST /api/pair` creates a pairing code and `GET /auth/connect/{code}`
redeems it; the `opencode pair` command wraps this flow.
