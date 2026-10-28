{ lib, pkgs, ... }:

let
  mntDir = "/work";

in {
  home.username = "x";
  home.homeDirectory = "/home/x";
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  systemd.user.enable = false;

  nix.enable = true;
  nix.package = pkgs.nix;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home.sessionVariables = {
    CLAUDE_CONFIG_DIR = "${mntDir}/claude";
    CODEX_HOME = "${mntDir}/codex";
  };

  home.packages = with pkgs; [ 
    less
    file
    curl
    wget
    nix
    cacert
    bash-completion
    nix-bash-completions
  ];

  programs.home-manager.enable = true;

  programs.claude-code.enable = true;

  programs.codex.enable = true;
  programs.codex.settings = {
    default_permissions = ":danger-full-access";
    sandbox_mode = "danger-full-access";
    approval_policy = "never";
  };

  programs.git = {
    enable = true;
    settings.user.name = "Nick Spinale";
    settings.user.email = "nick@nickspinale.com";
    settings.core.editor = "vim";
    ignores = [
      "**/result"
      "**/result-*"
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
      noremap <space> <nop>
      noremap <del> <nop>
      noremap <bs> <nop>
      noremap <cr> <nop>
      noremap Y <nop>

      nnoremap <space>j :bprev<cr>
      nnoremap <space>k :bnext<cr>
      nnoremap <space>d :Wipeout<cr>

      nnoremap <space>n gT
      nnoremap <space>m gt

      nnoremap <space>q :quit<cr>
      nnoremap <space>w :write<cr>
      nnoremap <space>e :e<space>
      nnoremap <space>t :tabe<space>
      nnoremap <space>y :quit!<cr>

      fun s:nrbufs()
        let i = bufnr('$')
        let j = 0
        while i > 0
          if buflisted(i)
            let j += i
          endif
          let i -= 1
        endwhile
        return j
      endfun

      fun s:my_wipeout()
        let n = s:nrbufs()
        if n == 1
          quit
        else
          bwipeout
        endif
      endfun

      command Wipeout call <sid>my_wipeout()
      command WWipeout write | Wipeout

      inoremap <c-z> <esc>:WWipeout<cr>
      noremap <c-z> :WWipeout<cr>
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
        gdu() {
            (
                set -eux -o pipefail;
                u=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
                git diff $u
            )
        }

        # Prompt

        reset="\[$(tput sgr0)\]"
        symbol="\[$(tput setaf 6)\]"
        text="\[$(tput setaf 2)\]"

        if printf '%s' "$LANG" | egrep -qi 'utf-?8'; then
            lambda='λ'
            arrow='→'
        else
            lambda='\\'
            arrow='->'
        fi

        PS1="$text \u@\h $symbol$lambda$text \w $symbol$arrow$reset "
      ''
      # would ideally be in .profile, but must be after last sourcing of nix.sh
      (lib.mkAfter ''
        if [ -z "''${IN_NIX_SHELL+x}" ]; then
          shell_drv=/work/shell.drv
          if [ -e "$shell_drv" ]; then
            # restore_tmpdir="$(declare -px TMPDIR 2>/dev/null)"
            # eval "$(nix-shell "$shell_drv" --run 'declare -px' 2>/dev/null)"
            # eval "$restore_tmpdir"
            eval "$(nix-shell "$shell_drv" --run 'declare -px' 2>/dev/null | grep -Ev '^declare -x TMP(DIR)?=')"
          fi
        fi
      '')
    ];
  };

}
