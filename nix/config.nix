{ lib, pkgs, ... }:

{
  imports = [
    ./vscode.nix
  ];

  home.username = "x";
  home.homeDirectory = "/home/x";
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  systemd.user.enable = false;

  nix.enable = true;
  nix.package = pkgs.nix;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home.packages = with pkgs; [
    nix
    cacert
    nix-bash-completions

    less
    file
    curl
    wget
    openssl
    git

    gnumake
    python3

    gh
  ];

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };

  programs.claude-code = {
    enable = true;
    settings = {
      remoteControlAtStartup = true;
    };
    skills = {
      repo-memory = ./claude-skills/repo-memory;
    };
  };

  programs.codex = {
    enable = true;
    settings = {
      default_permissions = ":danger-full-access";
      sandbox_mode = "danger-full-access";
      approval_policy = "never";
    };
  };

  programs.git = {
    enable = true;
    settings.user.name = "Nick Spinale";
    settings.user.email = "nick@nickspinale.com";
    settings.core.editor = "vim";
    ignores = [
      "result"
      "result-*"
      ".direnv"
      "**/.claude/settings.local.json"
    ];
  };

  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      show-mode-in-prompt = "on";
    };
  };

  programs.vim = {
    enable = true;

    extraConfig = ''
      set nobackup

      noremap <space> <nop>
      noremap <del> <nop>
      noremap <bs> <nop>
      noremap <cr> <nop>
      noremap Y <nop>

      nnoremap Y y$

      noremap <cr> :

      nnoremap <space>q :quit<cr>
      nnoremap <space>w :write<cr>
      nnoremap <space>e :e<space>
      nnoremap <space>t :tabe<space>
      nnoremap <space>y :quit!<cr>

      noremap <space>[ :set paste<cr>
      noremap <space>] :set nopaste<cr>

      nnoremap <space>j :bprev<cr>
      nnoremap <space>k :bnext<cr>
      nnoremap <space>d :WipeoutOrQuit<cr>

      nnoremap <space>n gT
      nnoremap <space>m gt

      inoremap <c-z> <esc>:WWipeoutOrQuit<cr>
      noremap <c-z> :WWipeoutOrQuit<cr>

      fun s:wipeout_or_quit()
        if len(getbufinfo({'buflisted': 1})) == 1
          quit
        else
          bwipeout
        endif
      endfun

      command WipeoutOrQuit call <sid>wipeout_or_quit()
      command WWipeoutOrQuit write | WipeoutOrQuit
    '';
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historySize = 100000;
    historyFileSize = 100000;

    shellAliases = {
      "gs" = "git status";
      "gd" = "git diff";
      "gb" = "git branch";
      "ga" = "git add -A :/";
      "gc" = "git commit";
      "gx" = "gs && ga && gs && gcx";
      "gca" = "git commit --amend";
      "gcx" = "git commit -m x";
      "gcy" = "git commit -m y";
      "gcd" = "git commit -m d";
      "gl" = "git log";
      "glo" = "git log --oneline";
      "gm" = "git submodule update --init --recursive";
      "gri" = "git rebase -i";
      "grc" = "git rebase --continue";
      "gra" = "git rebase --abort";
      "gk" = "git checkout";
      "gkb" = "git checkout -b";
    };

    initExtra = lib.mkMerge [
      ''
        PS1='\u@\h:\w\$ '

        gdu() {
          (
              set -eux -o pipefail;
              u=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
              git diff $u
          )
        }
      ''
    ];
  };

}
