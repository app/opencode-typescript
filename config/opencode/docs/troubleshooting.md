# Troubleshooting

In-container problems and their fixes. Host-side problems are in the
repository's `docs/troubleshooting.md`.

## Node versions

- A version requested by `.nvmrc`/`.node-version`/`.tool-versions`/`mise.toml`
  that is not installed is downloaded on demand; on non-x86_64 (or for older
  versions) this uses the slow `unofficial-builds.nodejs.org` mirror — the
  mise config has long timeouts and retries for that, so let the download
  finish instead of restarting it.
- `mise ls` shows installed versions; the pinned LTS is recorded in the image
  labels (the user can read them on the host with `docker image inspect`).

## Missing tools

- The global TypeScript tooling (`tsc`, `typescript-language-server`,
  `prettier`) and the Corepack shims (`pnpm`, `yarn`) are installed for the
  pinned Node. When the project activates a different version, tools missing
  for that version are not found; add them as project devDependencies
  instead of relying on the global install.
