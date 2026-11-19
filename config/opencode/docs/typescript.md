# TypeScript

## Node.js

Node is managed by `mise`. The Node LTS current at image build time is
installed at build time (recorded in `versions.json` and in the image labels)
and is the default:

- `.nvmrc`, `.node-version`, `.tool-versions` and `mise.toml` in the project
  are honored automatically.
- A version that is not installed yet is downloaded on demand: on x86_64 the
  pinned version comes from the official musl builds at nodejs.org, other
  versions and architectures from `unofficial-builds.nodejs.org` (slow — the
  mise config has long timeouts and retries for that).
- `mise ls` shows installed and active versions; `mise x node@N -- <cmd>` runs
  a command with another version.

## Package managers

`npm` ships with Node; `pnpm` and `yarn` go through Corepack (installed from
npm at build time, since Node 25 no longer ships corepack) and follow the
`packageManager` field of `package.json`.

## TypeScript tooling

`tsc` (typescript), `typescript-language-server` and `prettier` are installed
globally for the pinned Node. The language server is wired into OpenCode
through the baked configuration (`lsp.typescript`), covering `.ts`, `.tsx`,
`.js`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`.

Format changed Markdown with
`prettier --write --prose-wrap preserve --embedded-language-formatting off`;
it pads tables so they stay aligned in a terminal.

## Python

`python3` comes from Alpine and `uv` manages virtual environments and
packages:

```bash
uv venv
uv pip install -r requirements.txt
uvx ruff check .
```

Do not install packages into the system interpreter with `pip`.

## Native builds

`gcc`/`g++`, `make`, `pkg-config`, `linux-headers` and `openssl-dev` are
available, so `node-gyp` builds work when a package has no prebuilt binary.
Keep build dependencies to the current session; a permanent one belongs in
the image (ask the user).
