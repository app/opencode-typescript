---
name: env-setup
description: Offer to copy the runtime .env template when runtime variables such as forge tokens are missing, and explain how to fill it in
---

# Env setup

Use this skill when a required runtime environment variable is missing or
empty, or when a model or provider request fails with an authentication
error (for example HTTP 401, "missing API key", or a provider reporting no
credentials).

The image ships a documented runtime env template at
`/home/opencode/.env.example`. Values are passed at runtime only (`--env-file`
or a Kubernetes Secret) and are never baked into the image.

No key is required for the free built-in models: until the user connects a
provider, the session runs on OpenCode's free models (provider `opencode`).
The OpenRouter key is only needed for OpenRouter models; it arrives either in
the environment (`OPENROUTER_API_KEY`) or as a stored account from the TUI's
`/connect` command or `opencode auth login openrouter`. If the user wants
OpenRouter models and the key is missing or invalid, copying the template
does not fix it: tell the user to connect in the TUI with `/connect` (the key
is stored on the `opencode-state` volume) or to set `OPENROUTER_API_KEY` in
the env file and restart. Use this skill for the remaining variables.

## Check

List which variables are currently set:

```sh
env | grep -E '^(OPENROUTER_API_KEY|OPENCODE_PASSWORD|GH_TOKEN|GITLAB_TOKEN|FORGEJO_TOKEN)=' || true
```

## Actions

1. List the missing variables in a table with their purpose. The template at
   `/home/opencode/.env.example` documents every variable.
2. Offer to copy the template into the working folder (the project directory
   is mounted from the host, so the file ends up on the host):

   ```sh
   cp /home/opencode/.env.example .env
   ```

3. Explain that the user fills in the values on the host and restarts the
   container with the file:

   - Docker/Podman: add `--env-file .env` to the run command and start the
     container again.
   - Kubernetes: update the `Secret` referenced by the Deployment and let
     the pod restart.

4. Remind the user:

   - Add `.env` to `.gitignore`; never commit the file.
   - Keep it readable only by the user: `chmod 600 .env`.
   - Never print or echo the values, and never write them into the
     repository or the logs.

## Variables

| Variable                                     | Purpose                                                                                                                                  |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `OPENROUTER_API_KEY`                         | API key for OpenRouter models. Optional: the free built-in models work without it; the stored account wins over this variable.           |
| `OPENCODE_PASSWORD`                          | Password for the OpenCode server (HTTP API). Optional: when empty, the server generates one and prints it to the container log on start. |
| `GH_TOKEN`                                   | GitHub token for git over HTTPS and the `gh` CLI. Optional.                                                                              |
| `GITLAB_TOKEN`                               | GitLab token for git over HTTPS, the `glab` CLI and API calls. Optional.                                                                 |
| `GITLAB_URL`                                 | Self-hosted GitLab host (default `https://gitlab.com`). Optional.                                                                        |
| `FORGEJO_URL`                                | Forgejo/Gitea instance URL; required for `FORGEJO_TOKEN`. Optional.                                                                      |
| `FORGEJO_TOKEN`                              | Forgejo/Gitea token for git and the REST API. Optional.                                                                                  |
| `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`       | Author identity for git commits. Optional.                                                                                               |
| `GIT_COMMITTER_NAME` / `GIT_COMMITTER_EMAIL` | Committer identity for git commits. Optional.                                                                                            |
