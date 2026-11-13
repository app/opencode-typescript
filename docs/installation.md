# Installation

How to pull the image, create the runtime env file, and start the first
server.

## Requirements

- [Docker](https://www.docker.com/) or [rootless Podman](https://podman.io/).
  For Podman, enable subuid mappings so `--userns=keep-id` works
  (`subuid`/`subgid` entries in `/etc/subuid` and `/etc/subgid`).
- An OpenRouter API key for the default model (any other provider can be
  added later in the baked config).
- For the TUI, an [OpenCode](https://opencode.ai) client on the host.

## Pull the image

The image is published to GHCR by the GitHub Actions workflow:

```bash
podman pull ghcr.io/app/opencode-typescript:latest
docker pull ghcr.io/app/opencode-typescript:latest
```

Tags: `latest`, `oc-<opencode-version>-node<node-version>` (the exact toolchain
combination) and `<YYYYMMDD>` (build date). See
[Updating](updating.md) for how versions are chosen.

## Create the env file

Copy the template from the repository (or from the image at
`/home/opencode/.env.example`) and fill in the values:

```bash
cp .env.example ~/.config/opencode-container/env
chmod 600 ~/.config/opencode-container/env
$EDITOR ~/.config/opencode-container/env
```

Set at least `OPENROUTER_API_KEY`. Leave `OPENCODE_PASSWORD` empty to have the
server generate a password and print it to the container log. See
[Security notes](security.md) for how secrets are handled.

## Start the server

Run from the project directory you want the agent to work in:

```bash
podman run -d --name opencode --userns=keep-id -p 4096:4096 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state:/home/opencode/.local \
  --env-file "$HOME/.config/opencode-container/env" \
  ghcr.io/app/opencode-typescript:latest
```

The same command works with `docker run` (drop `--userns=keep-id`). The
`opencode-state` volume keeps credentials and the session database across
restarts.

Then connect a client: see [Access](api.md).

## Uninstall

Remove the container and the state volume:

```bash
podman rm -f opencode
podman volume rm opencode-state
```
