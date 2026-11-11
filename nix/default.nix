let
  nixpkgsSource = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs";
    ref = "nixpkgs-unstable";
    rev = "4fe25e12eb9f4c744966dd3de5a05246cf098601";
    shallow = true;
  };

  pkgs = import nixpkgsSource {};

  homeManagerSource = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager";
    rev = "82ce401aa350502897c3f2e85f384d61cd3b0b6d";
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
