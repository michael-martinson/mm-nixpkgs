inputs:
let
  inherit (inputs.nixpkgs) lib;

  inherit (lib.attrsets) genAttrs;
  inherit (lib) mkEnableOption mkOption types;
in
rec {
  # Paths of every module.nix below `directory`, at any depth.
  modulesFromDirectoryRecursive =
    directory:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = directory + "/${name}";
        in
        if type == "directory" then
          modulesFromDirectoryRecursive path
        else if type == "regular" && name == "module.nix" then
          [ path ]
        else
          [ ]
      ) (builtins.readDir directory)
    );

  # Function that takes a function (system -> Any) and generates an Attrset
  defaultSystems = genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # Packages that should be available for any shell
  defaultShellPackages =
    pkgs: with pkgs; [
      zellij
      git

      # terminal utils
      usbutils
      tree
      jq
      wget

      # neovim - configuratios set in overlay
      neovim
      # lazy vim deps
      fd
      ripgrep
      lazygit
      fzf
      python3
      nodejs
      gcc

      # nix dev
      nixd
      nixfmt

      # rust dev
      rustc
      cargo
      rust-analyzer
    ];

  fishShellInit = ''
    function fish_greeting
      string join "" -- "Welcome to the " (set_color brred) "Fantastic " (set_color brgreen) "Fancy "  (set_color brblue) "Fish " (set_color brcyan) "Shell"
    end

    function fish_prompt
      set -g __fish_git_prompt_color blue
      set -g __fish_git_prompt_showcolorhints true
      set -g __fish_git_prompt_color_branch blue

      set -g __fish_git_prompt_showdirtystate true
      set -g __fish_git_prompt_showuntrackedfiles true
      set -g __fish_git_prompt_showupstream auto

      if set -q SHELL_NAME
        set_color -i magenta
        echo -n "[$SHELL_NAME] "
      end
      set_color normal
      echo -n (prompt_pwd --full-length-dirs=2)
      echo -n (fish_git_prompt)
      set_color --bold bryellow
      echo ""
      echo -n "♱ "
      set_color normal
    end

    function fish_right_prompt
      set -l last_status $status

      # Prompt status only if its not 0
      set -l stat
      if test $last_status -ne 0
          set stat (set_color red)"[$last_status]"(set_color normal)
      end

      echo -n "$stat"
    end
  '';

  # Option declarations shared by every module that can notify on an AI
  # agent being done or needing input (mm.pi, mm.claude, mm.ai). Spliced
  # directly into an options tree, e.g. `options.mm.pi.notifications =
  # notificationOptions { };`. withClaudePush adds the Claude-only native
  # mobile push toggle - not script-driven, so hasScriptNotify ignores it.
  notificationOptions =
    { withClaudePush ? false }:
    {
      ntfy = {
        enable = mkEnableOption "a push to an ntfy topic when a harness is done or needs input";
        server = mkOption {
          description = "ntfy server.";
          type = types.str;
          default = "https://ntfy.sh";
        };
        topic = mkOption {
          description = "ntfy topic. Treat this as a shared secret: anyone who knows it can read your notifications.";
          type = types.str;
        };
      };

      pushover = {
        enable = mkEnableOption "a Pushover notification when a harness is done or needs input";
        userKeyCommand = mkOption {
          description = "Command that prints the Pushover user key. A command, not a plain value, so the key does not land in the Nix store.";
          type = types.listOf types.str;
        };
        apiTokenCommand = mkOption {
          description = "Command that prints the Pushover application API token. A command, not a plain value, so the token does not land in the Nix store.";
          type = types.listOf types.str;
        };
      };

      command = mkOption {
        description = "Extra shell command to run on notify, in addition to any backend above. Called with the message as $1.";
        type = types.nullOr types.str;
        default = null;
      };
    }
    // lib.optionalAttrs withClaudePush {
      claudePush.enable = mkEnableOption "Claude Code's own mobile push when it needs input (needs the mobile app linked)";
    };

  # True when a script-driven backend (as opposed to claudePush, which is
  # native to Claude) is on for a resolved `notifications` config value.
  hasScriptNotify = notifications: notifications.ntfy.enable || notifications.pushover.enable || notifications.command != null;

  # Builds the shared notify-dispatch script for a resolved `notifications`
  # config value. Takes pkgs explicitly (like defaultShellPackages above),
  # since it is not available in this file's own scope.
  mkNotifyScript =
    pkgs: notifications:
    pkgs.writeShellScript "mm-notify" ''
      message="$1"
      ${lib.optionalString notifications.ntfy.enable ''
        ${pkgs.curl}/bin/curl -fsS -d "$message" "${notifications.ntfy.server}/${notifications.ntfy.topic}" >/dev/null 2>&1 || true
      ''}
      ${lib.optionalString notifications.pushover.enable ''
        user_key=$(${lib.escapeShellArgs notifications.pushover.userKeyCommand})
        api_token=$(${lib.escapeShellArgs notifications.pushover.apiTokenCommand})
        ${pkgs.curl}/bin/curl -fsS \
          --form-string "token=$api_token" \
          --form-string "user=$user_key" \
          --form-string "message=$message" \
          https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
      ''}
      ${lib.optionalString (notifications.command != null) ''
        ${notifications.command} "$message" || true
      ''}
    '';
}
