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

      # neovim - LazyVim config set by mm.neovim
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

  # Option declarations shared by every module that can notify on an AI
  # agent being done or needing input (mm.pi, mm.claude, mm.ai). Spliced
  # directly into an options tree, e.g. `options.mm.pi.notifications =
  # notificationOptions { };`. withClaudePush adds the Claude-only native
  # mobile push toggle - not script-driven, so hasScriptNotify ignores it.
  notificationOptions =
    {
      withClaudePush ? false,
    }:
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
  hasScriptNotify =
    notifications:
    notifications.ntfy.enable || notifications.pushover.enable || notifications.command != null;

  # Builds the mm-notify invocation (package.nix in ../packages/mm-notify)
  # for a resolved `notifications` config value: the binary plus flags, as
  # one shell-safe string - usable directly in a hook `command`, or as a
  # full command for something that shells out itself (see mm.pi's
  # extension). Takes pkgs explicitly (like defaultShellPackages above),
  # since it is not available in this file's own scope. Each caller builds
  # its own string from its own `notifications` value, so mm.claude and
  # mm.pi can use different settings without touching shared/global state.
  mkNotifyCommand =
    pkgs: notifications:
    lib.concatStringsSep " " (
      [ "${pkgs.mm-notify}/bin/mm-notify" ]
      ++ lib.optionals notifications.ntfy.enable [
        "--ntfy-server"
        (lib.escapeShellArg notifications.ntfy.server)
        "--ntfy-topic"
        (lib.escapeShellArg notifications.ntfy.topic)
      ]
      ++ lib.optionals notifications.pushover.enable [
        "--pushover-user-key-command"
        (lib.escapeShellArg (lib.escapeShellArgs notifications.pushover.userKeyCommand))
        "--pushover-api-token-command"
        (lib.escapeShellArg (lib.escapeShellArgs notifications.pushover.apiTokenCommand))
      ]
      ++ lib.optionals (notifications.command != null) [
        "--command"
        (lib.escapeShellArg notifications.command)
      ]
    );
}
