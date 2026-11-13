# opencode-typescript

A container image that runs [OpenCode](https://opencode.ai) as a server, tuned for
TypeScript development. GitHub Actions builds and publishes it to GHCR on every push
and on a schedule, always with the current upstream versions (rolling latest). The
image ships a TypeScript-focused toolchain: current Node LTS via mise, TypeScript,
the TypeScript language server, Prettier, pnpm/yarn, git and the usual agent
tooling, and a non-root user (uid 1000) with a restricted sudo policy.

The default entrypoint starts the OpenCode server (`opencode serve` on port 4096), so
the same image serves three kinds of users:

- a human in the TUI, connecting from the host or via a forwarded port;
- a human in the web UI, through the pairing flow;
- an external agent through the HTTP API (Basic auth, username `opencode`).

Secrets (API keys, the server password, tokens) are host-side only: they are passed
with `--env-file` or a Kubernetes Secret. The image ships a documented `env.example`
template, and a built-in agent skill offers to copy it into the working folder when
credentials are missing.

## Quick start

```bash
# 1. Create the env file from the template
cp .env.example ~/.config/opencode-container/env
chmod 600 ~/.config/opencode-container/env
$EDITOR ~/.config/opencode-container/env          # set OPENROUTER_API_KEY

# 2. Run the server from your project directory (rootless Podman)
podman run -d --name opencode --userns=keep-id -p 4096:4096 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  --env-file "$HOME/.config/opencode-container/env" \
  ghcr.io/<owner>/opencode-typescript:latest

# 3. Connect an OpenCode client (TUI) from the host
opencode --server http://localhost:4096
```

The same `docker run` works without `--userns=keep-id`. With the port forwarded,
the web UI is available at `http://localhost:4096` (pairing flow), and agents talk to
the HTTP API with Basic auth — see [Access](docs/api.md). Running OpenCode in
Kubernetes: see [Kubernetes](docs/kubernetes.md).

## Documentation

| Document                                   | Contents                                                          |
| ------------------------------------------ | ----------------------------------------------------------------- |
| [Installation](docs/installation.md)       | Requirements, pulling the image, the env file setup               |
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
