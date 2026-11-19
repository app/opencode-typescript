# Toolchain

The image ships a TypeScript development toolchain: search tools, Node.js,
TypeScript tooling and native build tools are available out of the box. This
page is a reference for everyone who runs the image; the agent's usage guide
is baked with the configuration
([config/opencode/docs/typescript.md](../config/opencode/docs/typescript.md)).

| Area       | Tools                                                                                                      |
| ---------- | ---------------------------------------------------------------------------------------------------------- |
| Search     | `rg` (ripgrep), `fd`, `ast-grep` (`sg`)                                                                    |
| Data       | `jq`, `yq`                                                                                                 |
| Node.js    | `mise`, current Node LTS, `npm`, `pnpm`, `yarn`                                                            |
| TypeScript | `typescript` (`tsc`), `typescript-language-server`, `prettier`                                             |
| Python     | `python3`, `uv`                                                                                            |
| Git        | `git`, `openssh-client`, `gh`, `glab`                                                                      |
| Build      | `gcc`/`g++`, `make`, `linux-headers`, `pkgconf`, `openssl-dev` (node-gyp)                                  |
| Shell      | `bash`, `shellcheck`, `shfmt`, GNU userland (`coreutils`, `findutils`, `grep`, `sed`, `gawk`, `diffutils`) |
| Misc       | `less`, `file`, `tree`, `curl`, `xz`, `unzip`, `zip`, `tzdata`                                             |

System tools are the GNU versions, not BusyBox applets, so commands that rely
on GNU flags work as expected.

## Node.js

Node is managed by [mise](https://mise.jdx.dev). The Node LTS current at
build time is installed at image build time (recorded in `versions.json` and
in the image labels) and is the default. `.nvmrc`, `.node-version`,
`.tool-versions` and `mise.toml` in the mounted project are honored
automatically; a version that is not installed yet is downloaded on demand
(on x86_64 the pinned version comes from the official musl builds at
nodejs.org, other versions and architectures use the slow
`unofficial-builds.nodejs.org` mirror). `pnpm` and `yarn` go through Corepack
(installed from npm, since Node 25 no longer ships it) and follow
`packageManager` in `package.json`.

## TypeScript

`typescript`, `typescript-language-server` and `prettier` are installed
globally for the pinned Node at build time. The language server is wired into
OpenCode through the baked configuration (`lsp.typescript`), covering
`.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`.

## Python

`python3` comes from Alpine and `uv` manages virtual environments and
packages. The agent does not install packages into the system interpreter.

## Installing extra packages

The user the container runs as has passwordless sudo (the policy matches
any user), so the agent can install Alpine packages when a task needs them.
Runtime installs are not persisted: they disappear with the container. Add
the package to the `Containerfile` for a permanent tool. The usage policy is
defined in the baked `AGENTS.md`; see [Security notes](security.md).
