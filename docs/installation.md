# Installation

How to install the launcher, pull the image, create the runtime env file, and
open the first session.

## Requirements

- [Docker](https://www.docker.com/) or [rootless Podman](https://podman.io/).
  For Podman, enable subuid mappings so `--userns=keep-id` works
  (`subuid`/`subgid` entries in `/etc/subuid` and `/etc/subgid`).
- An OpenRouter API key for the default model (any other provider can be
  added later in the baked config).
- Nothing else: the TUI runs inside the container, so no OpenCode client is
  needed on the host.

## Pull the image

The image is published to GHCR by the GitHub Actions workflow:

```bash
podman pull ghcr.io/app/opencode-typescript:latest
docker pull ghcr.io/app/opencode-typescript:latest
```

Tags: `latest`, `oc-<opencode-version>-node<node-version>` (the exact toolchain
combination) and `<YYYYMMDD>` (build date). See
[Updating](updating.md) for how versions are chosen.

## The launcher

The repository ships `bin/opencode-ts`, a thin wrapper over podman/docker: it
resolves the engine (Podman first, override with `OPENCODE_TS_ENGINE`), mounts
the current project and the `opencode-state` volume, finds the env file, and
passes all remaining arguments to opencode unchanged.

```bash
git clone https://github.com/app/opencode-typescript
install -m755 opencode-typescript/bin/opencode-ts "$HOME/.local/bin/opencode-ts"
# make sure $HOME/.local/bin is in your PATH
```

Or just copy `bin/opencode-ts` anywhere in your PATH. Its environment
variables: `OPENCODE_TS_ENGINE`, `OPENCODE_TS_IMAGE`, `OPENCODE_TS_ENV_FILE`,
`OPENCODE_TS_PROJECT`, `OPENCODE_TS_STATE`, and `OPENCODE_TS_RUN_ARGS` for
extra raw engine arguments (for example `-p 4096:4096`).

## Create the env file

Copy the template from the repository (or from the image at
`/home/opencode/.env.example`) and fill in the values:

```bash
cp .env.example ~/.config/opencode-typescript/env
chmod 600 ~/.config/opencode-typescript/env
$EDITOR ~/.config/opencode-typescript/env
```

Set at least `OPENROUTER_API_KEY`. `OPENCODE_PASSWORD` is only needed in
server mode; leave it empty to have the server generate a password and print
it to the container log. The launcher finds this file automatically
(`OPENCODE_TS_ENV_FILE` → `./.env` → `~/.config/opencode-typescript/env`). See
[Security notes](security.md) for how secrets are handled.

## Open the first session

From the project directory you want the agent to work in:

```bash
opencode-ts
```

The TUI opens inside the container; the project is mounted at
`/home/opencode/projects/<name>`. To run the server instead (web UI, HTTP
API), see [Usage](usage.md#start-the-server-web-ui-http-api).

## Uninstall

Remove the container and the state volume:

```bash
podman rm -f opencode
podman volume rm opencode-state
```
