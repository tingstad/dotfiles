# Claude Code dev image inspired by
# https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile
#
FROM ubuntu:26.04

RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  man-db \
  unzip \
  gnupg2 \
  gh \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  tzdata \
  curl \
  gosu \
  unminimize \
  golang-go \
  openjdk-21-jdk \
  maven \
  python3 \
  nodejs \
  && yes | unminimize && apt-get clean && rm -rf /var/lib/apt/lists/*

ARG USERNAME=dev
ARG UID
ARG GID
ARG TZ

ENV TZ="$TZ"
ENV USERNAME="$USERNAME"

RUN groupadd -g $GID $USERNAME || true \
    && useradd -m -u $UID -g $GID $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/${USERNAME}/.local/bin:$PATH"

COPY <<"EOF" /usr/local/bin/entrypoint.sh
#!/bin/bash
set -eu

if [ "$(id -u):$(id -g)" != "${HOST_UID}:${HOST_GID}" ]; then
    echo "User mismatch: $(id -u):$(id -g) != ${HOST_UID}:${HOST_GID}"
    exit 1
fi

git config --global \
  url."https://${AMEDIA_READ_TOKEN}:x-oauth-basic@github.com/amedia/".insteadOf \
  "https://github.com/amedia/"
go env -w GOPRIVATE='github.com/amedia/*'

if [ -e "$HOME/.config_gcloud" ]; then
    ln -s ~/.config_gcloud ~/.config/gcloud
fi

exec "$@"
EOF

WORKDIR /workspace

ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
