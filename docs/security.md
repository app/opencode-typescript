# Security notes

## Trust model

- OpenCode runs as the non-root user `opencode` (uid/gid 1000) with
  passwordless sudo. The sudo policy is broad by design (`NOPASSWD: ALL`) and
  constrained by the usage rules in the baked `AGENTS.md`; container root
  maps to a subuid on the host (rootless Podman) or to root in the pod
  (Kubernetes). Treat the container as the security boundary: the agent can
  effectively do anything the container can.
- The baked permissions allow the agent to `edit` files, run `shell`
  commands, and `webfetch` URLs without prompts, so it works autonomously.
  Only mount projects and tokens the agent is allowed to touch.
- The container runs the agent, not your desktop: do not mount sensitive
  host directories (SSH agent, cloud credentials) unless the task needs them.

## Secrets

- Secrets live only on the host or on the state volume: the runtime env file
  (`chmod 600`), the calling environment, a Kubernetes `Secret`, or a
  connected account (`opencode auth login`). Nothing secret is baked into the
  image; the image ships the documented template
  (`/home/opencode/.env.example`) instead.
- Every process in the container, including the agent, sees the forwarded
  variables. A forge token (`GH_TOKEN`, `GITLAB_TOKEN`, `FORGEJO_TOKEN`) is
  usable by the agent for anything that token can do — prefer a dedicated
  token with the minimum scopes.
- The `OPENCODE_PASSWORD` (or the generated one printed to the log) protects
  the HTTP API with Basic auth in server mode. Keep the log private when the
  password is generated.
- The state volume (`/home/opencode/.local`) holds provider credentials and
  the session database; treat it as sensitive.
- Never commit a `.env` file. The `env-setup` skill keeps the agent from
  writing secrets into the repository and reminds about `chmod 600`.

## Network

- In server mode the server listens on `0.0.0.0` inside the container. Expose
  the port only to the networks that need it (host port, `ClusterIP` service,
  or a `LoadBalancer` with authentication in front). The default TUI mode does
  not listen on any port.
- Pairing links are single-use and expire in 5 minutes; web sessions last
  30 days and are revoked when the password changes.
