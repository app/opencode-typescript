# Installation

How to open the first session. There is nothing to install: the image is
pulled automatically on the first run, and the TUI runs inside the container,
so no OpenCode client is needed on the host.

## Requirements

- [Docker](https://www.docker.com/) or [rootless Podman](https://podman.io/).
  For Podman, enable subuid mappings so the
  `--userns=keep-id:uid=1000,gid=1000` flag works (`subuid`/`subgid` entries
  in `/etc/subuid` and `/etc/subgid`).
- Nothing else: OpenCode's free built-in models work without any account or
  key. An [OpenRouter](https://openrouter.ai/) API key is optional — see
  [More models](#more-models-optional).

## Open the first session

From the project directory you want the agent to work in:

Podman:

```bash
podman run -it --rm --userns=keep-id:uid=1000,gid=1000 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --detach-keys="ctrl-],ctrl-q" \
  ghcr.io/app/opencode-typescript:latest
```

Docker (the same, with `--user` instead of `--userns`):

```bash
docker run -it --rm --user "$(id -u):$(id -g)" \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --detach-keys="ctrl-],ctrl-q" \
  ghcr.io/app/opencode-typescript:latest
```

`--userns=keep-id:uid=1000,gid=1000` (Podman) maps the image's built-in user
(uid 1000) onto your host user, so files the agent creates are uid 1000 in
the container and yours on the host; the Docker command passes `--user
"$(id -u):$(id -g)"` instead, running the agent as your host UID directly.

The TUI opens inside the container; the project is mounted read-write at
`/home/opencode/projects/<name>` and OpenCode starts inside it, so the
session opens your project directly. The `opencode-state-<user>` volume
(one per user) keeps credentials and the session database across runs. The session starts on OpenCode's free built-in model — start typing
right away, no key needed; the sidebar's `/connect` hint leads to other
models (see [More models](#more-models-optional)).

## More models (optional)

The free built-in models need no key. To use OpenRouter models, connect
OpenRouter once; two ways, and when both are present, the stored account
wins.

### Option 1: connect in the TUI (`/connect`)

With the TUI open, type `/connect`, pick OpenRouter, and enter the API key.
The credential is stored in your `opencode-state-<user>` volume, so every later run
has the models. The same credential can be stored from the host without the
TUI:

```bash
podman run -it --rm --userns=keep-id:uid=1000,gid=1000 \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --detach-keys="ctrl-],ctrl-q" \
  ghcr.io/app/opencode-typescript:latest opencode auth login openrouter
```

The same works with Docker (with `--user "$(id -u):$(id -g)"` instead of
`--userns`). Remove the stored key the same way, with `opencode auth logout
openrouter` in place of `auth login openrouter`.

### Option 2: environment file

Keep the key on the host: put it in a `.env` file in the project folder —
ask the agent to create it (it copies the template from the image into the
current folder, which is on the host), or copy
[.env.example](../.env.example) from the repository — fill in
`OPENROUTER_API_KEY`, keep it private with `chmod 600 .env` and add it to
`.gitignore`, and pass it on the run command:

```bash
podman run -it --rm --userns=keep-id:uid=1000,gid=1000 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --detach-keys="ctrl-],ctrl-q" \
  --env-file .env \
  ghcr.io/app/opencode-typescript:latest
```

The same works with Docker (with `--user "$(id -u):$(id -g)"` instead of
`--userns`). See [Security notes](security.md) for how secrets are handled.

Either way, the OpenRouter models then appear in the TUI's model picker —
pick the one you want to work with; the pick is remembered on the
`opencode-state-<user>` volume and used on later runs.

## The launcher (optional)

The repository ships `bin/opencode-ts`, a thin wrapper over podman/docker for
people who prefer a shorter command: it resolves the engine (Podman first,
override with `OPENCODE_TS_ENGINE`), mounts the current project and the
`opencode-state-<user>` volume, finds the env file on its own
(`OPENCODE_TS_ENV_FILE` → `./.env` → `~/.config/opencode-typescript/env`), and
passes all remaining arguments to opencode unchanged. Fetch the single file
from the repository and install it:

```bash
curl -fsSL https://raw.githubusercontent.com/app/opencode-typescript/main/bin/opencode-ts \
  -o /tmp/opencode-ts
install -m755 /tmp/opencode-ts "$HOME/.local/bin/opencode-ts"
```

Then run `opencode-ts` from the project directory (`opencode-ts -r
../frontend` mounts a sibling read-only, `OPENCODE_TS_RUN_ARGS="-p 4096:4096"`
publishes the port in server mode). It is optional: every launcher flag has a
plain `run` equivalent shown in [Usage](usage.md).

## Image tags

The image is published to GHCR by the GitHub Actions workflow. Tags:
`latest`, `oc-<opencode-version>-node<node-version>` (the exact toolchain
combination) and `<YYYYMMDD>` (build date). See [Updating](updating.md) for
how versions are chosen.

## Uninstall

Remove the image and the state volume:

```bash
podman rmi ghcr.io/app/opencode-typescript:latest
podman volume rm opencode-state-$(id -un)
```
