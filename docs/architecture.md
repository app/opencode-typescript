# Architecture

Repository layout, the image, and the GitHub Actions pipeline.

## Layout

```text
.
├── AGENTS.md                         # instructions for agents working on this repository
├── Containerfile                     # OpenCode image + toolchain, non-root uid 1000
├── .env.example                      # runtime env template (copied into the image)
├── versions.json                     # pinned toolchain versions (updated by the bot PR)
├── .github/workflows/build.yml       # build, publish, smoke test, pin updates
├── scripts/
│   └── resolve-versions.sh           # resolves the current OpenCode and Node LTS
├── config/
│   ├── bin/entrypoint.sh             # git identity, gh auth setup-git, exec "$@"
│   ├── gitconfig                     # generic gitconfig for the non-root user
│   ├── mise/config.toml              # mise settings (musl, slow-mirror timeouts)
│   ├── sudoers.d/opencode            # passwordless sudo policy
│   └── opencode/                     # copied to /home/opencode/.config/opencode
│       ├── opencode.jsonc            # default model, OpenRouter, permissions, LSP
│       ├── AGENTS.md                 # agent instructions (public, no personal data)
│       └── skills/env-setup/SKILL.md # offers the env template when keys are missing
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
upstream version and the Node LTS version are build args supplied by the
workflow; they are never hardcoded and are recorded as image labels
(`org.opencode-typescript.opencode`, `org.opencode-typescript.node`).

The image bakes configuration, not secrets:

- `config/opencode/` → `/home/opencode/.config/opencode/` (default model,
  provider reading `{env:OPENROUTER_API_KEY}`, autonomous permissions, the
  TypeScript LSP, the `env-setup` skill, the `AGENTS.md` policy);
- `config/gitconfig` → `/home/opencode/.gitconfig` (generic identity);
- `.env.example` → `/home/opencode/.env.example` (the runtime env template);
- `config/bin/entrypoint.sh` → `/usr/local/bin/entrypoint.sh` (git identity
  from the environment, `gh auth setup-git` when `GH_TOKEN` is set, then
  `exec "$@"`).

The default command starts the OpenCode server on `0.0.0.0:4096`; any other
command can be passed to the container. See [Usage](usage.md) and
[Access](api.md).

## CI pipeline

`.github/workflows/build.yml` runs on push to `main`, on a daily schedule, and
on demand (`workflow_dispatch`):

1. `scripts/resolve-versions.sh` resolves the latest stable OpenCode tag from
   the upstream GHCR image and the current Node LTS from
   `nodejs.org/dist/index.json`.
2. Buildx builds `linux/amd64` and pushes to GHCR with the tags `latest`,
   `oc-<opencode>-node<node>` and `<YYYYMMDD>`. The layer cache lives in a
   separate `opencode-typescript-buildcache` GHCR repository.
3. A smoke test starts the image, waits for `GET /api/info` with Basic auth,
   and checks the reported version.
4. The `update-pins` job re-resolves the versions and, when they differ from
   `versions.json` in the repository, opens a pull request updating the pins
   (`peter-evans/create-pull-request`). Merging it rebuilds and republishes
   the image. See [Updating](updating.md).
