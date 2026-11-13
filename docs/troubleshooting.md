# Troubleshooting

Common errors and fixes.

## The TUI does not start or looks broken

- The TUI needs an interactive terminal: run the container with `-it`.
  Without a TTY the TUI cannot start.
- No colors or a garbled screen: `TERM` is inherited from the calling
  environment, so make sure it is set on the host (for example
  `xterm-256color`).
- The TUI talks to the local process inside the container and needs no
  password; if a provider error appears, check `OPENROUTER_API_KEY` (below).
- The default command is the TUI; if the container starts a server instead,
  either a custom command was passed (for example by the k8s manifest) or the
  local image is stale. `podman run` and `docker run` reuse a local image
  without re-pulling it: run
  `podman pull ghcr.io/app/opencode-typescript:latest` and start again.

## The server does not respond (server mode)

- Server mode is an explicit command: the container must be started with
  `opencode serve --hostname 0.0.0.0 --port 4096` (the k8s manifest and the
  CI smoke test do this; the image default is the TUI).
- Check the container is running and the port is published:
  `podman ps` / `docker ps`, and the `-p 4096:4096` flag.
- The server binds `0.0.0.0:4096` inside the container; without the port
  publication the host cannot reach it.
- Give it a few seconds on first start, then check the log for the
  `server listening on http://0.0.0.0:4096` line: `podman logs opencode`.
- In Kubernetes, the pod must be `Ready` (TCP probe) and the Service must
  select `app: opencode`; `kubectl port-forward svc/opencode 4096:4096`.

## Authentication errors (HTTP 401, server mode)

- The username is always `opencode`; only the password changes.
- When `OPENCODE_PASSWORD` is empty, the server generated a password and
  printed it to the container log on start (`podman logs opencode`,
  `kubectl logs deploy/opencode`).
- Pairing links for the web UI do not use the password at all; the browser
  session is created through the one-time link.

## No model or provider errors

- A 401/"missing API key" from OpenRouter means `OPENROUTER_API_KEY` is not
  set in the container environment. Set it in the env file (or the
  Kubernetes Secret) and restart the container with `--env-file` / the
  updated Secret.
- Inside the container, the `env-setup` skill offers to copy the template
  from `/home/opencode/.env.example` into the working folder when variables
  are missing.

## Git operations fail

- Git over HTTPS is preconfigured by the entrypoint from the tokens in the
  container environment: `GH_TOKEN` (GitHub, via `gh auth setup-git`),
  `GITLAB_TOKEN` (+ `GITLAB_URL`) and `FORGEJO_TOKEN` (+ `FORGEJO_URL`).
  Check that the token for the host you push to is set.
- Commits are signed with the `GIT_AUTHOR_*` / `GIT_COMMITTER_*` variables or
  the baked generic identity; set the variables in the env file.
- If the repository is owned by a different host user, use
  `--userns=keep-id` (Podman) or `--user $(id -u):$(id -g)` (Docker).

## Node version problems in the project

- A version requested by `.nvmrc`/`mise.toml` that is not installed is
  downloaded on demand; on non-x86_64 or for older versions this uses the
  slow `unofficial-builds.nodejs.org` mirror (mise is configured with long
  timeouts and retries for that).
- `mise ls` shows installed versions; the pinned LTS is recorded in the image
  labels (`docker image inspect`).

## The image looks stale

- Pull the tag you expect: `docker pull ghcr.io/app/opencode-typescript:latest`
  and compare the labels with the current pins in `versions.json`.
- To force a new build without waiting for the schedule, run the
  `Build` workflow from the repository's Actions page.
