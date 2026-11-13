# opencode-typescript

A container image that runs [OpenCode](https://opencode.ai) for TypeScript development.
GitHub Actions builds and publishes it to [GHCR](https://github.com) on every release
and on a schedule, always with the current upstream versions (rolling latest). The
image targets a TypeScript developer: current Node LTS via mise, TypeScript, the
TypeScript language server, Prettier, pnpm/yarn, git and the usual agent tooling.

The user is a human (TUI) or an agent (OpenCode server/API). Key properties:

- **Safely**: OpenCode runs as a non-root user (uid 1000) with a restricted sudo
  policy; the container is the security boundary.
- **Secrets are host-side only**: API keys and tokens are passed at runtime; the
  image ships a documented `env.example` template, and a built-in agent skill offers
  to copy it into the working folder when credentials are missing.
- **Rolling versions**: each workflow run resolves the latest OpenCode release and
  Node LTS, rebuilds the multi-arch image (amd64 + arm64), smoke-tests it and
  republishes it.

## Quick start

Pull the image from GHCR and start it from your project directory:

```bash
# rootless Podman
podman run -it --rm \
  --userns=keep-id \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  --env-file "$HOME/.config/opencode-container/env" \
  ghcr.io/<owner>/opencode-typescript:latest
```

```bash
# Docker
docker run -it --rm \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  --env-file "$HOME/.config/opencode-container/env" \
  ghcr.io/<owner>/opencode-typescript:latest
```

Create the env file first: `cp .env.example ~/.config/opencode-container/env` and fill
in the provider keys. Inside the image the template lives at
`/usr/share/opencode/env.example`. Running OpenCode as a server (API) for agent
usage: see [Kubernetes](docs/kubernetes.md).

## Documentation

| Document                             | Contents                                                             |
| ------------------------------------ | -------------------------------------------------------------------- |
| [Installation](docs/installation.md) | Requirements, pulling the image, the launcher script, env file setup |
| [Usage](docs/usage.md)               | Running the container, mounts, the launcher, passing secrets         |
| [Kubernetes](docs/kubernetes.md)     | Running OpenCode as a server (API) with Deployment, Secret and PVC   |
| [Toolchain](docs/toolchain.md)       | Installed tools, Node.js and mise, installing extra packages         |
| [Architecture](docs/architecture.md) | Repository layout, image build, the GitHub Actions pipeline          |
| [Updating](docs/updating.md)         | How versions are resolved and how image releases work                |
| [Security notes](docs/security.md)   | Trust model and secret handling                                      |

## Security

OpenCode runs as uid 1000 with a restricted sudo policy, so treat the container as
the security boundary. Secrets live only on the host (the runtime env file, the
calling environment, or a Kubernetes Secret) and are never baked into the image.
See [Security notes](docs/security.md) for details.

## Plan

Work on this project is tracked in [docs/PLAN.md](docs/PLAN.md).
