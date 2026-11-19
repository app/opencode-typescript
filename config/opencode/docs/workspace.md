# Workspace

You run inside the container; the user works on the host, in the same project
directory.

## The project

- The project is mounted read-write from the host at
  `/home/opencode/projects/<name>` (the name is the host directory name) and is
  the working directory when it is the only project mount.
- Edits, new files and commits made there land directly on the host, so the
  user sees them in their editor. Do not copy the project somewhere else to
  work on it.
- Sibling projects may be mounted read-only under `/home/opencode/projects/`;
  treat them as reference material.

## State

- `/home/opencode/.local` is the `opencode-state-<user>` volume. It keeps
  credentials, the session database, user-installed tools (`$HOME/.local`)
  and caches. It survives container restarts; the rest of the container
  filesystem does not.
- `/home/opencode/.config/opencode` is baked into the image (instructions,
  skills, OpenCode configuration). Do not edit it: changes disappear when the
  container restarts and are overwritten by the next image.
- The runtime environment template is `/home/opencode/.env.example`. When a
  variable is missing, use the `env-setup` skill to copy the template into the
  project.

## The entrypoint

The entrypoint runs before the command: it defaults the git author and
committer identity to `opencode-agent` (overridden by the `GIT_AUTHOR_*` and
`GIT_COMMITTER_*` variables), configures git credentials for the forge host
from `GH_TOKEN`, `GITLAB_TOKEN` or `FORGEJO_TOKEN` when set, `cd`s into the
project when it is the only mount, and execs the command.

## Commands and packages

- The image is Alpine-based and runs as a non-root user with passwordless
  sudo; `sudo apk add` is allowed only for packages missing for the current
  task (rules in `AGENTS.md`).
- Node.js and the TypeScript tooling are managed by `mise` under `/opt/mise`;
  see `/home/opencode/.config/opencode/docs/typescript.md`.
