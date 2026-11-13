# Usage

Running the container: the TUI, the server mode, mounts, and secrets.

## Open the TUI (default)

The default command is the interactive TUI inside the container. With the
[launcher](installation.md#the-launcher), run it from the project directory:

```bash
opencode-ts
```

Or with a plain engine command (Podman shown; Docker is the same without
`--userns=keep-id`):

```bash
podman run -it --rm --userns=keep-id \
  --name "opencode-$(basename "$PWD")" \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  --env-file "$HOME/.config/opencode-typescript/env" \
  ghcr.io/app/opencode-typescript:latest
```

No server, no published port, and nothing installed on the host. The project
directory is mounted read-write at `/home/opencode/projects/<name>` and is
the working directory.

## Start the server (web UI, HTTP API)

Server mode is an explicit command on top of the same image:

```bash
# via the launcher (foreground; publishes the port through OPENCODE_TS_RUN_ARGS)
OPENCODE_TS_RUN_ARGS="-p 4096:4096" opencode-ts serve --hostname 0.0.0.0 --port 4096

# or a plain detached run
podman run -d --name opencode --userns=keep-id -p 4096:4096 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  --env-file "$HOME/.config/opencode-typescript/env" \
  ghcr.io/app/opencode-typescript:latest \
  opencode serve --hostname 0.0.0.0 --port 4096
```

To open the [web UI](api.md#web-ui), create a pairing link from inside the
running container:

```bash
podman exec -it opencode opencode pair   # or: docker exec -it opencode opencode pair
```

and open the printed link in a browser. The [HTTP API](api.md#http-api-agents)
is available under Basic auth on the same port.

## Mounts

| Host path               | Container path                   | Purpose                              |
| ----------------------- | -------------------------------- | ------------------------------------ |
| your project directory  | `/home/opencode/projects/<name>` | the agent's working project          |
| `opencode-state` volume | `/home/opencode/.local`          | credentials and the session database |

- Use `--userns=keep-id` with Podman so files created in the project keep your
  host ownership. With Docker, match the container user to your host UID if
  ownership matters: `--user "$(id -u):$(id -g)"` (the image runs as 1000 by
  default). The launcher does both automatically where the engine supports it.
- Mount sibling projects read-only with the launcher's `-r` flag
  (`opencode-ts -r ../frontend`) or extra `-v` mounts under
  `/home/opencode/projects/`.
- For Kubernetes, see [Kubernetes](kubernetes.md) instead.

## Passing secrets

Secrets are never baked into the image; they are passed at runtime:

```bash
--env-file path/to/env            # one NAME=value per line
-e OPENROUTER_API_KEY=...         # or individual variables
```

The launcher finds the env file on its own: `OPENCODE_TS_ENV_FILE`, then
`./.env` in the project directory, then
`~/.config/opencode-typescript/env`. The template documenting every variable
lives in the repository root (`.env.example`) and inside the image at
`/home/opencode/.env.example`. Variable reference:

| Variable                                     | Required            | Purpose                                                              |
| -------------------------------------------- | ------------------- | -------------------------------------------------------------------- |
| `OPENROUTER_API_KEY`                         | yes (default model) | API key for the default provider                                     |
| `OPENCODE_PASSWORD`                          | no (server mode)    | server password; when empty, one is generated and printed to the log |
| `GH_TOKEN`                                   | no                  | GitHub token for git over HTTPS and the `gh` CLI                     |
| `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`       | no                  | author identity for commits                                          |
| `GIT_COMMITTER_NAME` / `GIT_COMMITTER_EMAIL` | no                  | committer identity for commits                                       |

Inside the container the agent detects missing variables and offers to copy
the template into the working folder: see the `env-setup` skill. Never commit
or print secrets; see [Security notes](security.md).

## Other commands

The entrypoint execs the command you pass, so any other opencode command or a
shell works:

```bash
opencode-ts run "Explain this repository"      # one-shot prompt, no server
opencode-ts bash                                # a shell inside the container
```

## Logs

```bash
podman logs -f opencode      # or: docker logs -f opencode
```

In server mode, the generated server password (when `OPENCODE_PASSWORD` is
empty) is printed here on start.
