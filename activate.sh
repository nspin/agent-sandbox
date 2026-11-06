#!/bin/bash

. ~/.nix-profile/etc/profile.d/nix.sh

nix_build=$(realpath $(which nix-build))

rm ~/.profile
rm ~/.bashrc

nix-env -e nix

$($(nix_build) --no-out-link /here -A home.activationPackage)/activate
