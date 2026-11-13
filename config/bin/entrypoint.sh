#!/usr/bin/env bash
#
# Container entrypoint: prepares the runtime for OpenCode, then execs the
# requested command (default: the OpenCode server on 0.0.0.0:4096).
#
# Secrets are passed in through the environment (--env-file or a Kubernetes
# Secret). This script never reads or writes a .env file; the runtime env
# template is baked into the image at /home/opencode/.env.example for the
# env-setup agent skill.

set -euo pipefail

# Git identity: environment variables take precedence over the gitconfig
# baked into the image, so each user can set their own committer.
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-opencode-agent}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-agent@localhost}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-opencode-agent}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-agent@localhost}"

# GitHub: when a token is provided, configure git to authenticate with it.
# gh itself reads GH_TOKEN from the environment.
if [[ -n "${GH_TOKEN:-}" ]]; then
  gh auth setup-git
fi

exec "$@"
