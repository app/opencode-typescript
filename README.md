# opencode-typescript

A container image that runs [OpenCode](https://opencode.ai) for TypeScript
development. Nothing to install: one run command from your project directory
and the agent is working — the TUI opens inside the container.

## Quick start

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

On the first run the agent offers to set up the OpenRouter API key: it writes
a `.env` file into your project directory, you fill in the key, and the next
run adds `--env-file .env` to the command.

## The image

- **Rolling latest.** GitHub Actions builds and publishes the image to GHCR on
  every push and on a schedule, always with the current upstream OpenCode and
  Node LTS versions. Tags: `latest`,
  `oc-<opencode-version>-node<node-version>`, `<YYYYMMDD>` — see
  [Updating](docs/updating.md).
- **TypeScript toolchain.** Current Node LTS via mise, TypeScript and the
  TypeScript language server, Prettier, pnpm/yarn, git and the usual agent
  tooling — see [Toolchain](docs/toolchain.md).
- **Non-root.** The agent runs as uid 1000 with a restricted sudo policy.

## Three kinds of users

- A human in the TUI — the image default, as in the quick start above.
- A human in the web UI — server mode plus the pairing flow.
- An external agent — server mode plus the HTTP API (Basic auth, username
  `opencode`).

Server mode is an explicit command
(`opencode serve --hostname 0.0.0.0 --port 4096`); see
[Usage](docs/usage.md) and [Access](docs/api.md). Running OpenCode in
Kubernetes: [Kubernetes](docs/kubernetes.md).

## Secrets

Secrets (API keys, the server password, tokens) are host-side only: they are
passed with the runtime env file or a Kubernetes Secret. The image ships a
documented `.env.example` template, and a built-in agent skill offers to copy
it into the working folder when credentials are missing. See
[Security notes](docs/security.md).

## Documentation

| Document                                   | Contents                                                          |
| ------------------------------------------ | ----------------------------------------------------------------- |
| [Installation](docs/installation.md)       | Requirements, the first run, the API key, the optional launcher   |
| [Usage](docs/usage.md)                     | Running the container, mounts, passing secrets, command overrides |
| [Access](docs/api.md)                      | TUI, web UI and the HTTP API for agents, Basic auth, OpenAPI      |
| [Kubernetes](docs/kubernetes.md)           | Deployment, Service and Secret examples for server mode           |
| [Toolchain](docs/toolchain.md)             | Installed tools, Node.js and mise, installing extra packages      |
| [Architecture](docs/architecture.md)       | Repository layout, the image, the GitHub Actions pipeline         |
| [Updating](docs/updating.md)               | How versions are resolved and how image releases work             |
| [Security notes](docs/security.md)         | Trust model and secret handling                                   |
| [Troubleshooting](docs/troubleshooting.md) | Common errors and fixes                                           |

## Security

OpenCode runs as uid 1000 with a restricted sudo policy, so treat the container as
the security boundary. Secrets live only on the host (the runtime env file, the
calling environment, or a Kubernetes Secret) and are never baked into the image.
See [Security notes](docs/security.md) for details.
