# Updating

How versions are chosen and how image releases work.

## Rolling latest

The image always builds with the current upstream versions — there is nothing
to update on the host:

- **OpenCode**: `scripts/resolve-versions.sh` pages through the tag list of
  `ghcr.io/anomalyco/opencode` (anonymous GHCR token, `Link` header
  pagination) and keeps the newest semver tag, ignoring prereleases and
  moving tags.
- **Node LTS**: the newest entry with a truthy `lts` in
  `https://nodejs.org/dist/index.json`.
- **npm globals** (`typescript`, `typescript-language-server`, `prettier`):
  whatever is published on build day.

The workflow resolves them on every run (push to `main`, the daily schedule,
or `workflow_dispatch`) and rebuilds the image.

## Image tags

| Tag                                        | Meaning                                      |
| ------------------------------------------ | -------------------------------------------- |
| `latest`                                   | the newest published build                   |
| `oc-<opencode-version>-node<node-version>` | the exact toolchain combination, for pinning |
| `<YYYYMMDD>`                               | the build date                               |

Run the version that was current when you read the docs, or pin:

```bash
docker pull ghcr.io/<owner>/opencode-typescript:oc-2.3.0-node26.13.1
```

`docker image inspect` prints the pinned versions from the image labels.

## Pin updates in the repository

`versions.json` records the last resolved toolchain combination. The
`update-pins` job opens a pull request (branch
`chore/update-pinned-versions`) whenever the resolved versions differ from
the file. Merging the PR rebuilds and republishes the image; the schedule
keeps looking for newer versions on its own.

## Building locally

For a one-off build with a specific upstream version:

```bash
docker build \
  --build-arg OPENCODE_VERSION=2.3.0 \
  --build-arg NODE_VERSION=26.13.1 \
  -t opencode-typescript:local .
```

The `Containerfile` never hardcodes versions, so the workflow remains the
source of truth.
