# Installation

How to open the first session. There is nothing to install: the image is
pulled automatically on the first run, and the TUI runs inside the container,
so no OpenCode client is needed on the host.

## Requirements

- [Docker](https://www.docker.com/) or [rootless Podman](https://podman.io/).
  For Podman, enable subuid mappings so `--userns=keep-id` works
  (`subuid`/`subgid` entries in `/etc/subuid` and `/etc/subgid`).
- An OpenRouter API key for the default model (any other provider can be
  added later in the baked config).

## Open the first session

From the project directory you want the agent to work in:

```bash
# Podman
podman run -it --rm --userns=keep-id \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  ghcr.io/app/opencode-typescript:latest

# Docker (the same, without --userns=keep-id)
docker run -it --rm \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  ghcr.io/app/opencode-typescript:latest
```

The TUI opens inside the container; the project is mounted read-write at
`/home/opencode/projects/<name>` and is the working directory. The
`opencode-state` volume keeps credentials and the session database across
runs.

## Provide the API key

On the first run the agent detects the missing `OPENROUTER_API_KEY` and
offers to create a `.env` file in your project directory from the template
baked into the image (`/home/opencode/.env.example`). Fill in the key, keep
the file private (`chmod 600 .env`, add `.env` to `.gitignore`), and pass it
on the next run:

```bash
podman run -it --rm --userns=keep-id \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  --env-file .env \
  ghcr.io/app/opencode-typescript:latest
```

The same works with Docker (without `--userns=keep-id`). See
[Security notes](security.md) for how secrets are handled.

## The launcher (optional)

The repository ships `bin/opencode-ts`, a thin wrapper over podman/docker for
people who prefer a shorter command: it resolves the engine (Podman first,
override with `OPENCODE_TS_ENGINE`), mounts the current project and the
`opencode-state` volume, finds the env file on its own
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
podman volume rm opencode-state
```
