let
  nixpkgsSource =
    let
      rev = "8c91a71d13451abc40eb9dae8910f972f979852f"; # nixpkgs-unstable
    in
      builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
        sha256 = "sha256:04gfgn29680pd1lm61y4iqrjing6825wwlzs4fg8iynjzclclz3y";
      };

  pkgs = import nixpkgsSource {};

  homeManagerSource =
    let
      rev = "486595d2cf49cfcd649b58a284fa11ac0e34da22";
    in
      builtins.fetchTarball {
        url = "https://github.com/nix-community/home-manager/archive/${rev}.tar.gz";
        sha256 = "sha256:19xfzmpx223rp32q5vrzb8bh1m0pl78170f3z2rcal70c9mdlag6";
      };

  home = import "${homeManagerSource}/modules" {
    inherit pkgs;
    configuration = { ... }: {
      imports = [
        ./config.nix
      ];
      nix.nixPath = [
        "nixpkgs=${nixpkgsSource}"
      ];
      nixpkgs.config.allowUnfree = true;
    };
  };

  activate = pkgs.writeShellApplication {
    name = "activate";
    runtimeInputs = [
      pkgs.nix
    ];
    text = ''
      nix-env --set-flag priority 10 nix
      export HOME_MANAGER_BACKUP_EXT=hm-bak
      exec ${home.activationPackage}/activate
    '';
  };

in {
  inherit
    pkgs
    home
    activate
  ;
}
