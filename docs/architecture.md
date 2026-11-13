# Architecture

Repository layout, the image, and the GitHub Actions pipeline.

## Layout

```text
.
├── AGENTS.md                         # instructions for agents working on this repository
├── bin/opencode-ts                   # launcher: thin wrapper over podman/docker
├── Containerfile                     # OpenCode image + toolchain, built-in non-root user (uid 1000)
├── .env.example                      # runtime env template (copied into the image)
├── versions.json                     # pinned toolchain versions (updated by the bot PR)
├── .github/workflows/build.yml       # build, publish, smoke test, pin updates
├── scripts/
│   └── resolve-versions.sh           # resolves the current OpenCode and Node LTS
├── config/
│   ├── bin/entrypoint.sh             # git identity, forge credentials, cd into the project, exec "$@"
│   ├── gitconfig                     # generic gitconfig for the non-root user
│   ├── mise/config.toml              # mise settings (musl, slow-mirror timeouts)
│   ├── sudoers.d/opencode            # passwordless sudo policy (any user in the container)
│   └── opencode/                     # copied to /home/opencode/.config/opencode
│       ├── opencode.jsonc            # permissions, LSP (no model or provider pinned)
│       ├── AGENTS.md                 # agent instructions (public, no personal data)
│       └── skills/env-setup/SKILL.md # offers the env template when runtime variables are missing
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── secret.example.yaml
├── docs/                             # detailed documentation
└── README.md
```

## Image

`Containerfile` extends `ghcr.io/anomalyco/opencode:<version>` with the
[toolchain](toolchain.md) and a non-root `opencode` user (uid/gid 1000 by
default, overridable with `--build-arg UID=... --build-arg GID=...`). The
documented run commands override the user at runtime with
`--user "$(id -u):$(id -g)"` so that files created by the agent keep host
ownership; the home and mise directories are world-writable inside the
image so that any user the container runs as can write to them (the
container is a single-user trust boundary). The upstream version and the
Node LTS version are build args supplied by the workflow; they are never
hardcoded and are recorded as image labels
(`org.opencode-typescript.opencode`, `org.opencode-typescript.node`).

The image bakes configuration, not secrets:

- `config/opencode/` → `/home/opencode/.config/opencode/` (autonomous
  permissions, the TypeScript LSP, the `env-setup` skill, the `AGENTS.md`
  policy; no model or provider is pinned — the session runs on OpenCode's
  free built-in models until the user connects OpenRouter);
- `config/gitconfig` → `/home/opencode/.gitconfig` (generic identity);
- `.env.example` → `/home/opencode/.env.example` (the runtime env template);
- `config/bin/entrypoint.sh` → `/usr/local/bin/entrypoint.sh` (git identity
  from the environment, forge git credentials from `GH_TOKEN`,
  `GITLAB_TOKEN`, `FORGEJO_TOKEN` when set, a `cd` into the single mounted
  project when there is one, then `exec "$@"`).

The default command is the interactive TUI: `docker run -it ... image` opens
a session with no OpenCode installation on the host, in the mounted project
(the entrypoint `cd`s into it when it is the only project mount). The server
(`opencode serve --hostname 0.0.0.0 --port 4096`) is started explicitly —
the k8s deployment and the CI smoke test pass it as the container command.
See [Usage](usage.md) and [Access](api.md).

## CI pipeline

`.github/workflows/build.yml` runs on push to `main`, on a daily schedule, and
on demand (`workflow_dispatch`):

1. `scripts/resolve-versions.sh` resolves the latest stable OpenCode tag from
   the upstream GHCR image and the current Node LTS from
   `nodejs.org/dist/index.json`.
2. Buildx builds `linux/amd64` and pushes to GHCR with the tags `latest`,
   `oc-<opencode>-node<node>` and `<YYYYMMDD>`. The layer cache lives in a
   separate `opencode-typescript-buildcache` GHCR repository.
3. A smoke test asserts that the image default stays the TUI, starts the
   server explicitly, waits for `GET /api/info` with Basic auth, and checks
   the reported version.
4. The `update-pins` job re-resolves the versions and, when they differ from
   `versions.json` in the repository, opens a pull request updating the pins
   (`peter-evans/create-pull-request`). Merging it rebuilds and republishes
   the image. See [Updating](updating.md).
