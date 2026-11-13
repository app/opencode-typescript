# Access

How the three kinds of users reach the agent: a human in the TUI, a human in
the web UI, and an external agent through the HTTP API.

All of them talk to the same server started by the image's default command
(`opencode serve --hostname 0.0.0.0 --port 4096`).

## Authentication

The server is password-protected. Set `OPENCODE_PASSWORD` in the env file to
use a fixed password; when it is empty, the server generates a random one and
prints it to the container log on start.

- TUI/client connections pass the password through the `OPENCODE_PASSWORD`
  variable of the client process.
- Other HTTP clients use Basic auth. The username is always `opencode`, and
  only the password can be changed.

## TUI

Run an OpenCode client from the host (or any machine) pointed at the server:

```bash
OPENCODE_PASSWORD="a-long-secret" opencode --server http://localhost:4096
```

With the port forwarded (`-p 4096:4096`), the server address is
`http://localhost:4096`.

## Web UI

The web UI is served from the same server. To sign in, create a pairing link
with the `opencode` CLI connected to the server:

```bash
OPENCODE_PASSWORD="a-long-secret" opencode --server http://localhost:4096 pair
```

Open the printed link in a browser. Links work once and expire in 5 minutes;
sessions last 30 days. Changing the server password signs every session out.
Over SSH, forward the server port and open the link locally.

## HTTP API (agents)

An external agent creates a session and sends prompts through the REST API:

```bash
BASE=http://localhost:4096
AUTH="opencode:a-long-secret"

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
