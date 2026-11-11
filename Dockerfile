FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    # for nix installer
    xz-utils \
    # for nix
    git \
    && rm -rf /var/lib/apt/lists/*

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ARG UID
ARG GID

RUN set -eux; \
    if ! getent group $GID; then \
        groupadd --gid $GID x; \
    fi; \
    useradd \
        --uid $UID \
        --gid $GID \
        --groups sudo \
        --shell /home/x/.nix-profile/bin/bash \
        --create-home x;

RUN set -eux; \
    mkdir -p -m 0755 /nix; \
    chown $UID:$GID /nix;

USER $UID

RUN set -eux -o pipefail; \
    curl -sSf -L https://nixos.org/nix/install | \
        bash -s -- --yes --no-modify-profile --no-channel-add

ENV USER=x

VOLUME /nix

WORKDIR /work
