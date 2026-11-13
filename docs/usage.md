# Usage

Running the container: mounts, secrets, ports, and command overrides.

## Starting the server

The default command starts the OpenCode server:

```sh
opencode serve --hostname 0.0.0.0 --port 4096
```

Run the container from the project directory:

```bash
podman run -d --name opencode --userns=keep-id -p 4096:4096 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  --env-file "$HOME/.config/opencode-container/env" \
  ghcr.io/app/opencode-typescript:latest
```

Connect a TUI client from the host with
`opencode --server http://localhost:4096`, open the web UI in a browser, or
talk to the HTTP API: see [Access](api.md).

## Mounts

| Host path               | Container path                   | Purpose                              |
| ----------------------- | -------------------------------- | ------------------------------------ |
| your project directory  | `/home/opencode/projects/<name>` | the agent's working project          |
| `opencode-state` volume | `/home/opencode/.local`          | credentials and the session database |

- Use `--userns=keep-id` with Podman so files created in the project keep your
  host ownership. With Docker, match the container user to your host UID if
  ownership matters: `--user "$(id -u):$(id -g)"` (the image runs as 1000 by
  default).
- Add more project directories with extra `-v` mounts under
  `/home/opencode/projects/`.
- For Kubernetes, see [Kubernetes](kubernetes.md) instead.

## Passing secrets

Secrets are never baked into the image; they are passed at runtime:

```bash
--env-file path/to/env            # one NAME=value per line
-e OPENROUTER_API_KEY=...         # or individual variables
```

The template documenting every variable lives in the repository root
(`.env.example`) and inside the image at `/home/opencode/.env.example`.
Variable reference:

| Variable                                     | Required            | Purpose                                                              |
| -------------------------------------------- | ------------------- | -------------------------------------------------------------------- |
| `OPENROUTER_API_KEY`                         | yes (default model) | API key for the default provider                                     |
| `OPENCODE_PASSWORD`                          | no                  | server password; when empty, one is generated and printed to the log |
| `GH_TOKEN`                                   | no                  | GitHub token for git over HTTPS and the `gh` CLI                     |
| `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`       | no                  | author identity for commits                                          |
| `GIT_COMMITTER_NAME` / `GIT_COMMITTER_EMAIL` | no                  | committer identity for commits                                       |

Inside the container the agent detects missing variables and offers to copy
the template into the working folder: see the `env-setup` skill. Never commit
or print secrets; see [Security notes](security.md).

## Command overrides

The entrypoint execs the command you pass, so the image also serves one-shot
and interactive use:

```bash
# One-shot prompt, no server
docker run --rm -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  --env-file "$HOME/.config/opencode-container/env" \
  ghcr.io/app/opencode-typescript:latest opencode run "Explain this repository"

# Interactive shell as the opencode user
docker run -it --rm ghcr.io/app/opencode-typescript:latest bash
```

## Logs

```bash
podman logs -f opencode      # or: docker logs -f opencode
```

The generated server password (when `OPENCODE_PASSWORD` is empty) is printed
here on start.
