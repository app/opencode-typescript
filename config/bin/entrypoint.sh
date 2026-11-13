#!/usr/bin/env bash
#
# Container entrypoint: prepares the runtime for OpenCode, then execs the
# requested command (default: the interactive TUI).
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

# GitLab and Forgejo: optional forge tokens. When provided, each token is
# stored as a git credential for its host (the scheme is taken from the
# instance URL), so git over HTTPS/HTTP works without a password prompt.
# GITLAB_TOKEN defaults to gitlab.com; FORGEJO_TOKEN is only used together
# with FORGEJO_URL.
if [[ -n "${GITLAB_TOKEN:-}" || -n "${FORGEJO_TOKEN:-}${FORGEJO_URL:-}" ]]; then
  {
    if [[ -n "${GITLAB_TOKEN:-}" ]]; then
      url="${GITLAB_URL:-https://gitlab.com}"
      rest="${url#*://}"
      printf '%s://oauth2:%s@%s\n' "${url%%://*}" "$GITLAB_TOKEN" "${rest%%/*}"
    fi
    if [[ -n "${FORGEJO_TOKEN:-}" && -n "${FORGEJO_URL:-}" ]]; then
      rest="${FORGEJO_URL#*://}"
      printf '%s://git:%s@%s\n' "${FORGEJO_URL%%://*}" "$FORGEJO_TOKEN" "${rest%%/*}"
    fi
  } >"${HOME}/.git-credentials"
  chmod 600 "${HOME}/.git-credentials"
  git config --global credential.helper store
fi

exec "$@"
