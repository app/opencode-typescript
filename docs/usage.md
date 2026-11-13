# Usage

Running the container: the TUI, the server mode, mounts, and secrets.

## Open the TUI (default)

The default command is the interactive TUI inside the container. From the
project directory:

Podman:

```bash
podman run -it --rm --userns=keep-id --user "$(id -u):$(id -g)" \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  ghcr.io/app/opencode-typescript:latest
```

Docker (the same, without `--userns=keep-id`):

```bash
docker run -it --rm --user "$(id -u):$(id -g)" \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  ghcr.io/app/opencode-typescript:latest
```

No server, no published port, and nothing installed on the host. The project
directory is mounted read-write at `/home/opencode/projects/<name>`; when it
is the only project mount, OpenCode starts inside it, so the TUI opens your
project directly. If you have a `.env` file (see
[More models](installation.md#more-models-optional)), add `--env-file .env`
to the command. The optional [launcher](installation.md#the-launcher-optional)
wraps exactly this.

## Start the server (web UI, HTTP API)

Server mode is an explicit command on top of the same image:

```bash
podman run -d --name opencode --userns=keep-id --user "$(id -u):$(id -g)" -p 4096:4096 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --env-file .env \
  ghcr.io/app/opencode-typescript:latest \
  opencode serve --hostname 0.0.0.0 --port 4096
```

The same works with Docker (without `--userns=keep-id`); drop `-d` and add
`-it` for a foreground run. The [launcher](installation.md#the-launcher-optional)
equivalent is `OPENCODE_TS_RUN_ARGS="-p 4096:4096" opencode-ts serve
--hostname 0.0.0.0 --port 4096`.

To open the [web UI](api.md#web-ui), create a pairing link from inside the
running container:

Podman:

```bash
podman exec -it opencode opencode pair
```

Docker:

```bash
docker exec -it opencode opencode pair
```

and open the printed link in a browser. The [HTTP API](api.md#http-api-agents)
is available under Basic auth on the same port.

## Mounts

| Host path                      | Container path                   | Purpose                                                                          |
| ------------------------------ | -------------------------------- | -------------------------------------------------------------------------------- |
| your project directory         | `/home/opencode/projects/<name>` | the agent's working project; OpenCode starts inside it when it is the only mount |
| `opencode-state-<user>` volume | `/home/opencode/.local`          | credentials and the session database, one per user                               |

- `--user "$(id -u):$(id -g)"` (in every command above) makes the agent run
  as your host user, so files it creates — in the project and on the state
  volume — keep your ownership. It is a no-op when your UID is 1000, the
  image's built-in user. With Podman it works together with
  `--userns=keep-id`, which maps your host UID into the container
  namespace.
- If you used an earlier version of this image, its state lived in a single
  shared volume, `opencode-state` (with permissions only uid 1000 could
  write). The commands above now use one volume per user,
  `opencode-state-<user>`; the old volume is simply not used anymore.
  Remove it when you no longer need it (`podman volume rm opencode-state`,
  or the Docker equivalent). Stored credentials are re-added with `/connect`.
- Mount sibling projects read-only with extra `-v` mounts under
  `/home/opencode/projects/`, for example
  `-v ../frontend:/home/opencode/projects/frontend:ro` (the launcher's
  `-r` flag wraps this). With several project mounts, OpenCode starts at
  the projects root; open a specific one by appending its directory to the
  run command: `opencode /home/opencode/projects/frontend`.
- For Kubernetes, see [Kubernetes](kubernetes.md) instead.

## Passing secrets

Secrets are never baked into the image; they are passed at runtime:

```bash
--env-file path/to/env            # one NAME=value per line
-e OPENROUTER_API_KEY=...         # or individual variables
```

The OpenRouter key is optional (the free built-in models need no key); to
connect, use the TUI's `/connect` command (see
[Installation](installation.md#more-models-optional)) — the stored account
wins over the environment.

By convention the file lives in the project directory (`.env`); the optional
[launcher](installation.md#the-launcher-optional) finds it on its own. The
template documenting every variable lives in the repository root
(`.env.example`) and inside the image at `/home/opencode/.env.example`.
Variable reference:

| Variable                                     | Required         | Purpose                                                              |
| -------------------------------------------- | ---------------- | -------------------------------------------------------------------- |
| `OPENROUTER_API_KEY`                         | no               | API key for OpenRouter models; the free built-in models need no key  |
| `OPENCODE_PASSWORD`                          | no (server mode) | server password; when empty, one is generated and printed to the log |
| `GH_TOKEN`                                   | no               | GitHub token for git over HTTPS and the `gh` CLI                     |
| `GITLAB_TOKEN`                               | no               | GitLab token for git, the `glab` CLI and the API                     |
| `GITLAB_URL`                                 | no               | self-hosted GitLab host (default `https://gitlab.com`)               |
| `FORGEJO_URL`                                | no               | Forgejo/Gitea instance URL, required for `FORGEJO_TOKEN`             |
| `FORGEJO_TOKEN`                              | no               | Forgejo token for git and the REST API                               |
| `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`       | no               | author identity for commits                                          |
| `GIT_COMMITTER_NAME` / `GIT_COMMITTER_EMAIL` | no               | committer identity for commits                                       |

When the agent is already running and a token or another variable is missing,
it can offer to copy the template into the working folder (the `env-setup`
skill). Never commit or print secrets; see [Security notes](security.md).

## Other commands

The entrypoint execs the command you pass, so any other opencode command or a
shell works — append it to the run command:

```bash
podman run -it --rm --userns=keep-id --user "$(id -u):$(id -g)" \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  ghcr.io/app/opencode-typescript:latest \
  opencode run "Explain this repository"
```

That is a one-shot prompt with no server. For a shell inside the container,
replace the command with `bash`.

## Logs

Podman:

```bash
podman logs -f opencode
```

Docker:

```bash
docker logs -f opencode
```

In server mode, the generated server password (when `OPENCODE_PASSWORD` is
empty) is printed here on start.
