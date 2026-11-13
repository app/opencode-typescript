# Plan: opencode-typescript

A public GitHub project whose workflow builds and publishes a multi-arch
(amd64 + arm64) container image for running OpenCode safely, tuned for
TypeScript development. The user is a human or an agent talking to OpenCode
through its API.

Source of the thesis list: [`bootstrap.md`](../bootstrap.md). The reference
architecture is `../opencode-container` (home-use setup, not a public release) —
use it as a structural guide, but rethink the installed software instead of
copying it.

## Decisions

| Question | Decision |
| --- | --- |
| Image registry | GHCR (`ghcr.io/<owner>/<image>`), native to GitHub Actions |
| Tool versions | Rolling latest: every workflow run resolves the current OpenCode release and Node LTS itself |
| Architectures | Multi-arch manifest: `linux/amd64` + `linux/arm64` |
| Run modes | Launcher script (podman/docker) + K8s manifests (server/API mode) + documented plain commands |
| Python | Excluded from the image; the agent installs on demand via `sudo apk` if needed |
| Secrets | Host-only (env file / environment / K8s Secret); the image ships a documented `.env` template only |

## Stages

### Stage 1 — repository skeleton

- `README.md` (≤100 lines: overview, quick start for podman/docker, docs index), `LICENSE` (MIT), `.gitignore`.
- `docs/PLAN.md` (this file) under git, with the mandatory `## Done / Next steps` section.

### Stage 2 — Containerfile

- Base: `ghcr.io/anomalyco/opencode:<latest>` — the version is supplied by the workflow at build time, never hardcoded.
- Non-root `opencode` user (uid/gid 1000:1000), sudoers policy (install Alpine packages on demand), `git config --system --add safe.directory '*'`.
- Rethought toolchain for a TypeScript developer (no home-lab extras from the reference):
  - core: `bash`, `git`, `git-lfs`, `openssh-client`, `curl`, `jq`, `yq`, GNU userland;
  - search: `ripgrep`, `fd`, `ast-grep` (`sg`);
  - TypeScript/Node: `mise` + current Node LTS (version resolved at build time), Corepack (`pnpm`, `yarn`), global `typescript`, `typescript-language-server`, `prettier`;
  - native builds: `build-base`, `linux-headers`, `pkgconf` (for `node-gyp`);
  - forge CLIs: `gh` (keep `glab` — decide at implementation time).
- Explicitly excluded from the reference: Python/`uv`, Node 18, Forgejo/`tea` helpers, Herdr, `sqlite`, `ctags`, and the rest of the home-use wiring.

### Stage 3 — secrets policy and the `.env` template

- Secrets live only on the host: the launcher's env file, the calling environment, or a K8s Secret. Nothing secret is baked into the image.
- `env.example` documenting every variable (provider API keys, git identity, `GH_TOKEN`, etc.) is kept in the repository root and baked into the image at a well-known path (`/usr/share/opencode/env.example`).

### Stage 4 — `env-setup` agent skill

- Baked into the image under `~/.config/opencode/skills/`: when the agent detects that no provider is configured or no tokens are set, it offers to copy the in-image template into the working folder or `~/.config/` and explains how to fill it in.
- A short secrets-policy summary in the baked `AGENTS.md`.

### Stage 5 — GitHub Actions workflow

- Triggers: `push` to main, `schedule` (daily), `workflow_dispatch`.
- Steps: resolve the latest OpenCode release (GitHub API) and the current Node LTS → build `linux/amd64` + `linux/arm64` (buildx + QEMU) → smoke test (`opencode --version`, `node -v`, `tsc --version`, …) → publish to GHCR.
- Tags: `latest`, `<opencode-version>`, `<opencode-version>-<date>`.
- Skip publishing when an image with the same version combination already exists, so scheduled runs do not re-tag identical images.

### Stage 6 — run modes

- Launcher script `opencode-container.sh` (podman, docker fallback): mounts the current project, reads the env file (`~/.config/opencode-container/env` or `./.env`), uses `--userns=keep-id` with podman, keeps a persistent volume for auth/sessions.
- `k8s/`: example Deployment + Secret + PVC — OpenCode in server mode (API) for agent usage.

### Stage 7 — documentation

- `docs/`: installation, usage (launcher / docker / k8s), toolchain, security, architecture, updating.
- Structure follows the `documentation` skill; format changed Markdown with `prettier` (`--prose-wrap preserve --embedded-language-formatting off`).

## Open details (resolve during implementation)

- Keep `glab` in the image?
- "Misc" utilities (`bat`, `delta`, `fzf`, `tree`, …) — which, if any, to keep?
- Image name in GHCR: default to the repository name `opencode-typescript`.

## Done / Next steps

- [x] Write the thesis list (`bootstrap.md`)
- [x] Review the reference architecture in `../opencode-container`
- [x] Agree on the plan (registry, versioning, arches, run modes, Python, secrets)
- [x] Record the plan in `docs/PLAN.md`
- [ ] Stage 1 — repository skeleton
- [ ] Stage 2 — Containerfile
- [ ] Stage 3 — secrets policy and the `.env` template
- [ ] Stage 4 — `env-setup` agent skill
- [ ] Stage 5 — GitHub Actions workflow
- [ ] Stage 6 — run modes
- [ ] Stage 7 — documentation
