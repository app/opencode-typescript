# Agent instructions

This file is the entry point for agents working on a host: install and run the
image, drive it over the HTTP API, and work on this repository. Humans start at
[README.md](README.md); the reference documentation for container users is in
[docs/](docs/).

## Install and run

Requirements: rootless Podman or Docker on the host. Check first:

```bash
command -v podman || command -v docker
```

If neither is installed, stop and ask the user; do not install a container
engine unsolicited.

From the project directory the agent should work in (`podman`; with Docker,
replace `--userns=keep-id:uid=1000,gid=1000` with
`--user "$(id -u):$(id -g)"`):

```bash
podman run -it --rm --userns=keep-id:uid=1000,gid=1000 \
  --name "opencode-$$" \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  --detach-keys="ctrl-],ctrl-q" \
  ghcr.io/app/opencode-typescript:latest
```

That starts the TUI for the user. The project is mounted read-write; the
`opencode-state-<user>` volume keeps credentials and the session database.
See [Installation](docs/installation.md) for models and the env file, and
[Usage](docs/usage.md) for mounts and other commands.

Secrets: put `NAME=value` lines in `.env` and add `--env-file .env`; never
print or commit them. The variable table is in
[Usage](docs/usage.md#passing-secrets).

## Drive the image over the HTTP API

Start server mode with a password you choose (`change-me` below):

```bash
podman run -d --rm \
  --name "opencode-$$" \
  --userns=keep-id:uid=1000,gid=1000 -p 4096:4096 \
  -v "$PWD:/home/opencode/projects/$(basename "$PWD")" \
  -v opencode-state-$(id -un):/home/opencode/.local \
  -e OPENCODE_PASSWORD=change-me \
  ghcr.io/app/opencode-typescript:latest \
  opencode serve --hostname 0.0.0.0 --port 4096
```

Wait until the server answers, export the same password, and drive the REST API
(the block needs `curl` and `jq` on the host; the canonical copy is in
[docs/api.md](docs/api.md#http-api-agents)):

<!-- canonical: api-flow -->

```bash
BASE=http://localhost:4096
AUTH="opencode:$OPENCODE_PASSWORD"

# Server info (also a good health check)
curl -fsS -u "$AUTH" "$BASE/api/info"

# Create a session
SESSION=$(curl -fsS -u "$AUTH" -X POST "$BASE/api/session" | jq -r .id)

# Send a prompt
curl -fsS -u "$AUTH" -X POST "$BASE/api/session/$SESSION/prompt" \
  -H "Content-Type: application/json" \
  -d '{"parts": [{"type": "text", "text": "Summarize this repository"}]}'

# Subscribe to server events
curl -fsS -u "$AUTH" -N "$BASE/api/event"
```

<!-- /canonical: api-flow -->

The username is always `opencode`. Events, permission replies and pairing are
documented in [Access](docs/api.md#http-api-agents). Logs and cleanup:

```bash
name="$(podman ps --format '{{.Names}}' | grep '^opencode-' | head -n1)"
podman logs -f "$name"
podman rm -f "$name"
```

## Work on this repository

This repository is the home of a container image that runs
[OpenCode](https://opencode.ai) for TypeScript development. GitHub Actions
builds and publishes the image to GHCR on every push to `main`, on a schedule,
and on demand. Read [docs/architecture.md](docs/architecture.md) for the layout
and the pipeline, and [docs/updating.md](docs/updating.md) for versioning.

### Environment limits

- Docker and Podman are not available in the default working environment. The
  image is built only by the GitHub Actions workflow, so validate changes
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
