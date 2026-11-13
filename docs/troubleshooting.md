# Troubleshooting

Common errors and fixes.

## The server does not respond

- Check the container is running and the port is published:
  `podman ps` / `docker ps`, and the `-p 4096:4096` flag.
- The server binds `0.0.0.0:4096` inside the container; without the port
  publication the host cannot reach it.
- Give it a few seconds on first start, then check the log for the
  `server listening on http://0.0.0.0:4096` line: `podman logs opencode`.
- In Kubernetes, the pod must be `Ready` (TCP probe) and the Service must
  select `app: opencode`; `kubectl port-forward svc/opencode 4096:4096`.

## Authentication errors (HTTP 401)

- The username is always `opencode`; only the password changes.
- When `OPENCODE_PASSWORD` is empty, the server generated a password and
  printed it to the container log on start (`podman logs opencode`,
  `kubectl logs deploy/opencode`).
- In the TUI client, the password comes from the client process'
  `OPENCODE_PASSWORD` variable, not from the container's.

## No model or provider errors

- A 401/"missing API key" from OpenRouter means `OPENROUTER_API_KEY` is not
  set in the container environment. Set it in the env file (or the
  Kubernetes Secret) and restart the container with `--env-file` / the
  updated Secret.
- Inside the container, the `env-setup` skill offers to copy the template
  from `/home/opencode/.env.example` into the working folder when variables
  are missing.

## Git operations fail

- Git over HTTPS needs `GH_TOKEN` in the container environment; the
  entrypoint runs `gh auth setup-git` when it is set.
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
