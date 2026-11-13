# Agent instructions for this repository

This repository is the home of a container image that runs
[OpenCode](https://opencode.ai) for TypeScript development. GitHub Actions
builds and publishes the image to GHCR on every push to `main`, on a schedule,
and on demand. Read [docs/architecture.md](docs/architecture.md) for the layout
and the pipeline, and [docs/updating.md](docs/updating.md) for versioning.

## Environment limits

- Docker and Podman are not available in the default working environment.
  The image is built only by the GitHub Actions workflow, so validate changes
  statically and let CI build them.
- Run the static checks below after touching the corresponding file types;
  they must pass before committing.

| File types                         | Check                                                                       |
| ---------------------------------- | --------------------------------------------------------------------------- |
| `*.sh`                             | `shellcheck` and `shfmt -i 2 -d` (must print no diff)                       |
| `*.md`                             | `prettier --check --prose-wrap preserve --embedded-language-formatting off` |
| `*.yml`, `*.yaml` (workflows, k8s) | `yq -e . file`                                                              |
| `*.jsonc`                          | strip `//` comment lines, then parse as JSON (node or jq)                   |

Format changed Markdown with
`prettier --write --prose-wrap preserve --embedded-language-formatting off`
before committing; it pads tables so they stay aligned in a terminal.

## Rules

- **Versions are never hardcoded** in the `Containerfile` or the workflow.
  `scripts/resolve-versions.sh` resolves the current OpenCode and Node LTS at
  CI time; `versions.json` is the pinned record and is updated only by the
  `update-pins` bot PR.
- **Secrets are host-side only.** Never commit a `.env` file, never print or
  echo tokens. `.env.example` is the template; it is baked into the image at
  `/home/opencode/.env.example` for the `env-setup` agent skill.
- **Documentation:** English, in `docs/` as short single-topic pages; link
  every page from the README index and cross-link related pages. Keep
  `README.md` at 100 lines or fewer. Update the affected docs in the same
  change as behavior, configuration, or setup.
- **Commits:** English, Conventional Commits (`feat:`, `fix:`, `docs:`,
  `chore:`, ...). Commit after each logical change, not one giant commit.
- **Two AGENTS.md files are different things.** The root file is for agents
  working on this repository. `config/opencode/AGENTS.md` is baked into the
  image and instructs the agent that runs inside it, for TypeScript work.
  Do not mix their concerns.

## After pushing

The push to `main` triggers the `Build` workflow. Watch the run (GitHub
Actions or `gh run list` / `gh run watch`), and on failure read the logs
(`gh run view <id> --log`) before changing anything. The smoke test checks
that the published image starts the server and answers `GET /api/info` with
Basic auth.
