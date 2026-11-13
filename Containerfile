# OpenCode image for TypeScript development.
#
# The upstream OpenCode version and the Node LTS version are resolved by the
# GitHub Actions workflow on every run and passed as build args. Do not
# hardcode versions here: versions.json in the repository is the pinned
# record, and the workflow is the source of truth for what gets built.
#
# Secrets are never baked in. The runtime env template is copied to
# /home/opencode/.env.example for the env-setup agent skill.
ARG OPENCODE_VERSION
ARG NODE_VERSION

FROM ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}

ARG UID=1000
ARG GID=1000
ARG OPENCODE_VERSION
ARG NODE_VERSION

# Recorded in the image for `docker image inspect` and troubleshooting.
LABEL org.opencode-typescript.opencode="${OPENCODE_VERSION}" \
      org.opencode-typescript.node="${NODE_VERSION}"

# Toolchain for a TypeScript developer: GNU userland, git and the GitHub
# CLI, search tools, JSON/YAML, a minimal Python, and the native build tools
# needed by node-gyp. bash must come before mise: its npm wrapper needs it.
RUN echo "Installing Alpine packages..." \
 && apk add --no-cache \
      bash \
      coreutils \
      findutils \
      grep \
      sed \
      gawk \
      diffutils \
      procps-ng \
      tzdata \
      less \
      file \
      tree \
      xz \
      unzip \
      zip \
      git \
      openssh-client \
      curl \
      jq \
      yq-go \
      ripgrep \
      fd \
      ast-grep \
      python3 \
      uv \
      build-base \
      linux-headers \
      pkgconf \
      openssl-dev \
      mise \
      github-cli \
      glab \
      shellcheck \
      shfmt \
      sudo \
 && ln -sf /usr/bin/ast-grep /usr/local/bin/sg \
 && addgroup -g "${GID}" opencode \
 && adduser -u "${UID}" -G opencode -h /home/opencode -D -s /bin/bash opencode \
 && mkdir -p /home/opencode/projects \
             /home/opencode/.cache \
             /home/opencode/.config \
             /home/opencode/.local/share/opencode \
             /home/opencode/.local/state/opencode \
             /opt/mise \
 && chown -R "${UID}:${GID}" /home/opencode /opt/mise \
 && git config --system --add safe.directory '*'

# Passwordless sudo lets the agent install Alpine packages for the current
# session. The usage policy lives in config/opencode/AGENTS.md.
COPY config/sudoers.d/opencode /etc/sudoers.d/opencode
RUN chmod 0440 /etc/sudoers.d/opencode && visudo -cf /etc/sudoers

# Only the mise config is needed for the Node install. The rest of the baked
# configuration is copied afterwards so editing it does not invalidate the
# Node layer.
COPY --chown=${UID}:${GID} config/mise/ /home/opencode/.config/mise/

USER ${UID}:${GID}
ENV HOME=/home/opencode \
    SHELL=/bin/bash \
    PATH=/opt/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    MISE_DATA_DIR=/opt/mise \
    MISE_CONFIG_DIR=/home/opencode/.config/mise \
    MISE_ALL_COMPILE=false \
    MISE_NODE_COMPILE=false \
    MISE_NODE_FLAVOR=musl \
    MISE_NODE_MIRROR_URL=https://unofficial-builds.nodejs.org/download/release/ \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    UV_LINK_MODE=copy \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

# nodejs.org publishes musl builds for x86_64, so install the Node LTS from
# there when possible. Other architectures fall back to the unofficial-builds
# mirror, which is also the runtime mirror for on-demand versions.
RUN if [ "$(apk --print-arch)" = "x86_64" ]; then \
      MIRROR=https://nodejs.org/dist/; \
    else \
      MIRROR=https://unofficial-builds.nodejs.org/download/release/; \
    fi \
 && echo "Downloading Node ${NODE_VERSION} (musl)..." \
 && MISE_CACHE_DIR=/tmp/mise-cache MISE_NODE_MIRROR_URL="$MIRROR" mise install node@${NODE_VERSION} \
 && rm -rf /tmp/mise-cache

# TypeScript tooling at the versions published on build day. Node 25 and
# newer no longer ship corepack, so install it from npm; it provides the
# pnpm and yarn shims that honor "packageManager" in package.json.
RUN echo "Installing TypeScript tooling..." \
 && mise exec node -- npm install -g corepack typescript typescript-language-server prettier \
 && mise exec node -- corepack enable \
 && mise reshim \
 && rm -rf /home/opencode/.npm

# Bake the OpenCode configuration into the image. Secrets are not stored
# here: they are passed at runtime through environment variables.
USER 0
COPY --chown=${UID}:${GID} config/opencode/ /home/opencode/.config/opencode/
COPY --chown=${UID}:${GID} config/gitconfig /home/opencode/.gitconfig
COPY --chown=${UID}:${GID} .env.example /home/opencode/.env.example
COPY --chown=root:root config/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER ${UID}:${GID}
WORKDIR /home/opencode/projects

# The default command is the interactive TUI, so a plain
# `docker run -it ... image` opens a session with no OpenCode installation
# on the host. Run the server explicitly for the web UI and the HTTP API:
# `docker run ... image opencode serve --hostname 0.0.0.0 --port 4096`.
# Any other command works too, for example
# `docker run ... image opencode run "Explain this repository"`.
EXPOSE 4096
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode"]
