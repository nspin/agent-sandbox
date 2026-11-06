#!/bin/bash

. ~/.nix-profile/etc/profile.d/nix.sh

nix=$(realpath $(which nix))

rm ~/.profile
rm ~/.bashrc

nix-env -e nix

$(${nix}-build --no-out-link /here -A home.activationPackage)/activate
