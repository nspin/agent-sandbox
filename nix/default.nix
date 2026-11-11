let
  nixpkgsSource = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs";
    ref = "nixpkgs-unstable";
    rev = "8c91a71d13451abc40eb9dae8910f972f979852f";
    shallow = true;
  };

  pkgs = import nixpkgsSource {};

  homeManagerSource = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager";
    rev = "486595d2cf49cfcd649b58a284fa11ac0e34da22";
    shallow = true;
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
