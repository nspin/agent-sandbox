#!/bin/bash

. ~/.nix-profile/etc/profile.d/nix.sh

ln -sf $(nix eval /work/rv/env#devShells.aarch64-linux.default.drvPath --raw) /work/shell.drv
