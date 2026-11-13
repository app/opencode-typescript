# Toolchain

The image is built for TypeScript agent work: search, Node.js, TypeScript
tooling and native build tools are available out of the box.

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
in the image labels) and is the default:

```bash
node -v                      # the Node LTS pinned at build time
mise ls                      # installed and active versions
mise x node@22 -- npm ci     # run a command with another version
```

`.nvmrc`, `.node-version`, `.tool-versions` and `mise.toml` in the mounted
project are honored automatically. A version that is not installed yet is
downloaded on demand; on x86_64 the pinned version comes from the official
musl builds at nodejs.org, and other versions and architectures use
`unofficial-builds.nodejs.org` (slow). `pnpm` and `yarn` go through Corepack
(installed from npm, since Node 25 no longer ships it) and follow
`packageManager` in `package.json`.

## TypeScript

`typescript`, `typescript-language-server` and `prettier` are installed
globally for the pinned Node at build time. The language server is wired into
OpenCode through the baked configuration (`lsp.typescript`), covering
`.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.mts`, `.cts`.

## Python

`python3` comes from Alpine and `uv` manages virtual environments and
packages:

```bash
uv venv
uv pip install -r requirements.txt
uvx ruff check .
```

Do not install packages into the system interpreter with `pip`.

## Installing extra packages

The user the container runs as has passwordless sudo (the policy matches
any user), so the agent can install Alpine packages when a task needs them:

```bash
sudo apk add --no-cache <package>
```

Runtime installs are not persisted: they disappear with the container. Add
the package to the `Containerfile` for a permanent tool. The usage policy is
defined in the baked `AGENTS.md`; see [Security notes](security.md).
