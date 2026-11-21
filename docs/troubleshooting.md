# Troubleshooting

Common errors and fixes.

## The TUI does not start or looks broken

- The TUI needs an interactive terminal: run the container with `-it`.
  Without a TTY the TUI cannot start.
- No colors or a garbled screen: `TERM` is inherited from the calling
  environment, so make sure it is set on the host (for example
  `xterm-256color`).
- The TUI talks to the local process inside the container and needs no
  password; if a provider error appears, check the OpenRouter key (below).
- The default command is the TUI; if the container starts a server instead,
  either a custom command was passed (for example by the k8s manifest) or the
  local image is stale. `podman run` and `docker run` reuse a local image
  without re-pulling it: run
  `podman pull ghcr.io/app/opencode-typescript:latest` and start again.
- The TUI opens at `/home/opencode/projects` instead of your project: that
  is expected when several projects are mounted (or none). Open a specific
  project by appending its directory to the run command:
  `opencode /home/opencode/projects/<name>`.
- `ctrl-p` (the command palette) does nothing: your run command lacks
  `--detach-keys="ctrl-],ctrl-q"`. The default detach sequence of
  podman/docker is `ctrl-p ctrl-q`, so the engine waits for `ctrl-q` and
  the key never reaches the TUI. Every command in this repository carries
  the flag; alternatively set `detachKeys` in your engine's client config
  file.
- Copying between the TUI and the host clipboard is limited in standard
  terminals: use kitty (Linux) or iTerm2 (macOS), see
  [Terminal](usage.md#terminal).

## The server does not respond (server mode)

- Server mode is an explicit command: the container must be started with
  `opencode serve --hostname 0.0.0.0 --port 4096` (the k8s manifest and the
  CI smoke test do this; the image default is the TUI).
- Check the container is running and the port is published — the `Names`
  column is the container name (used in the commands below, see
  [Usage](usage.md#logs)):
  `podman ps --format "table {{.ID}}\t{{.Status}}\t{{.Names}}\t{{.Ports}}" | grep opencode`
  (Docker: the same with `docker ps`), and the `-p 4096:4096` flag.
- The server binds `0.0.0.0:4096` inside the container; without the port
  publication the host cannot reach it.
- Give it a few seconds on first start, then check the log for the
  `server listening on http://0.0.0.0:4096` line: find the container name in
  [Usage](usage.md#logs), then `podman logs -f <name>`.
- In Kubernetes, the pod must be `Ready` (TCP probe) and the Service must
  select `app: opencode`; `kubectl port-forward svc/opencode 4096:4096`.

## Authentication errors (HTTP 401, server mode)

- The username is always `opencode`; only the password changes.
- When `OPENCODE_PASSWORD` is empty, the server generated a password and
  printed it to the container log on start (find the name in
  [Usage](usage.md#logs), then `podman logs -f <name>`; in Kubernetes:
  `kubectl logs deploy/opencode`).
- Pairing links for the web UI do not use the password at all; the browser
  session is created through the one-time link.

## No model or provider errors

- A 401/"missing API key" from OpenRouter means the container has no OpenRouter
  key: neither `OPENROUTER_API_KEY` in the environment nor a connected
  account. Connect once in the TUI with `/connect` (the key is stored on
  your `opencode-state-<user>` volume), or set the variable in the env file
  (or the
  Kubernetes Secret) and restart with `--env-file` / the updated Secret.
- Without any key the TUI opens on a free built-in model and the agent
  answers without a key. For more models, connect OpenRouter (see
  [Installation](installation.md#more-models-optional)).
- When the agent is running and another variable (for example a forge token)
  is missing, the `env-setup` skill offers to copy the template from
  `/home/opencode/.env.example` into the working folder.

## Git operations fail

- Git over HTTPS is preconfigured by the entrypoint from the tokens in the
  container environment: `GH_TOKEN` (GitHub, via `gh auth setup-git`),
  `GITLAB_TOKEN` (+ `GITLAB_URL`) and `FORGEJO_TOKEN` (+ `FORGEJO_URL`).
  Check that the token for the host you push to is set.
- Commits are signed with the `GIT_AUTHOR_*` / `GIT_COMMITTER_*` variables or
  the baked generic identity; set the variables in the env file.
- Permission denied on files in the project (the agent cannot create, edit
  or commit): the run command must carry the user mapping —
  `--userns=keep-id:uid=1000,gid=1000` (Podman) or `--user "$(id -u):$(id -g)"`
  (Docker), so files it writes are owned by your host user (every command in
  [Usage](usage.md) includes it). A state volume created by an older image
  needs a one-time removal first (Usage, Mounts).

## In-container problems

The agent inside the container follows its own guide, baked at
`/home/opencode/.config/opencode/docs/` (source:
[config/opencode/docs/](../config/opencode/docs/)): Node version downloads,
global tooling and other in-container issues. Ask the agent, or read the guide
in the repository.

## The image looks stale

- Pull the tag you expect: `docker pull ghcr.io/app/opencode-typescript:latest`
  and compare the labels with the current pins in `versions.json`.
- To force a new build without waiting for the schedule, run the
  `Build` workflow from the repository's Actions page.
