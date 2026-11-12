{ pkgs, ... }:

let
  hol4-vscode = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "hol4developers";
      name = "hol4-vscode";
      version = "0.4.3";
      hash = "sha256-whNrMOhi1NsC2O+fvtqPBGHS+nNj79/ygivupNP8g6Q=";
    };
  };

  codex = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "openai";
      name = "chatgpt";
      version = "26.5602.71036";
    } // {
      aarch64-linux = {
        arch = "linux-arm64";
        hash = "sha256-32/E7SI52Ny0ANR4+lwA94jq5Nfp+3t44i3Ujexy2Fg=";
      };
      x86_64-linux = {
        arch = "linux-x64";
        hash = "sha256-PWKj0Qqb+w96mD9WllYxBrMDBYNHON4gmLhQlAOIasI=";
      };
    }.${pkgs.stdenv.hostPlatform.system};
  };

  haskell = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "haskell";
      name = "haskell";
      version = "2.8.1";
      hash = "sha256-mAlEy5a83BRhUhA22AKheP6PPpfbrdGT6HsTKbFwJYs=";
    };
  };

  language-haskell = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "haskell";
      name = "language-haskell";
      version = "3.8.0";
      hash = "sha256-wDGvGKI+YDwkbYKV0ijnB3+NwWPZAuwLN4MpFV37KFs=";
    };
  };

  # Logging wrapper the Claude extension launches its claude process through
  # (claudeCode.claudeProcessWrapper). See claude-process-wrapper/README.md.
  claude-process-wrapper = pkgs.writers.writePython3Bin "claude-process-wrapper" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./claude-process-wrapper/claude-process-wrapper.py);

  vscodeServerExtensions = with pkgs.vscode-extensions; [
    anthropic.claude-code
    codex
    ms-vscode.cpptools
    ms-vscode.makefile-tools
    christian-kohler.path-intellisense
    streetsidesoftware.code-spell-checker
    tamasfe.even-better-toml
    rust-lang.rust-analyzer
    haskell
    language-haskell
    hol4-vscode
    leanprover.lean4
    mkhl.direnv
  ];

  # Same layout as programs.vscode with mutableExtensionsDir = false, but at the
  # VS Code Server's path, which programs.vscode doesn't support.
  vscodeServerExtensionsDir = pkgs.buildEnv {
    name = "vscode-server-extensions";
    paths = vscodeServerExtensions ++ [
      (pkgs.writeTextDir "share/vscode/extensions/extensions.json"
        (pkgs.vscode-utils.toExtensionJson vscodeServerExtensions))
    ];
  };

in {
  home.file.".vscode-server/extensions".source =
    "${vscodeServerExtensionsDir}/share/vscode/extensions";

  home.file.".vscode-server/data/Machine/settings.json".text = builtins.toJSON {
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = "off";
    "claudeCode.allowDangerouslySkipPermissions" = true;
    "claudeCode.initialPermissionMode" = "bypassPermissions";
    "claudeCode.claudeProcessWrapper" = "${claude-process-wrapper}/bin/claude-process-wrapper";
  };
}
