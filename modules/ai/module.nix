/*
  Shared AI agent setup for one user:

  - mm.ai.enable writes ./AGENTS.md to ~/.ai/AGENTS.md. Plain NixOS, no
    home-manager required.
  - mm.ai.claude.enable and mm.ai.pi.enable turn on Claude Code and/or Pi
    (pi.dev), independently. claude needs home-manager (for example
    inputs.mm-nixpkgs.nixosModules.homeManager) - home-manager.* must be
    declared in the system even if you never enable mm.ai.claude, the same
    way mm.secrets needs sops-nix declared. This is a GENERIC setup: no
    gateway, no API key wiring. A consumer with its own gateway-specific
    Claude Code module (mm.anduril.claude-code in mm-nixos-anduril) should
    use that instead of mm.ai.claude - do not enable both, they both try to
    set home-manager.users.<username>.programs.claude-code.

  - mm.ai.notifications fires one or more backends when a harness is done
    or needs input: Claude's own mobile push (claude only), ntfy, Pushover,
    or an arbitrary command. For Claude this uses its Notification/Stop
    hooks. Pi has no documented hook or notification system as of writing,
    so for Pi this wraps the `pi` binary and notifies when the process
    exits - this covers "done", not "needs input mid-session".
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    mkPackageOption
    optionals
    optionalString
    types
    ;
  cfg = config.mm.ai;

  notifyScript = pkgs.writeShellScript "mm-ai-notify" ''
    message="$1"
    ${optionalString cfg.notifications.ntfy.enable ''
      ${pkgs.curl}/bin/curl -fsS -d "$message" "${cfg.notifications.ntfy.server}/${cfg.notifications.ntfy.topic}" >/dev/null 2>&1 || true
    ''}
    ${optionalString cfg.notifications.pushover.enable ''
      user_key=$(${lib.escapeShellArgs cfg.notifications.pushover.userKeyCommand})
      api_token=$(${lib.escapeShellArgs cfg.notifications.pushover.apiTokenCommand})
      ${pkgs.curl}/bin/curl -fsS \
        --form-string "token=$api_token" \
        --form-string "user=$user_key" \
        --form-string "message=$message" \
        https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
    ''}
    ${optionalString (cfg.notifications.command != null) ''
      ${cfg.notifications.command} "$message" || true
    ''}
  '';

  # True when a script-driven backend is on (claudePush is native to Claude,
  # not script-driven, so it is not part of this).
  scriptNotifyEnabled =
    cfg.notifications.ntfy.enable || cfg.notifications.pushover.enable || cfg.notifications.command != null;

  piWithNotify = pkgs.writeShellScriptBin "pi" ''
    "${cfg.pi.package}/bin/pi" "$@"
    status=$?
    "${notifyScript}" "Pi session ended (exit $status)"
    exit $status
  '';
in
{
  options.mm.ai = {
    enable = mkEnableOption "shared AI agent rules in ~/.ai/AGENTS.md";

    username = mkOption {
      description = "The user that gets ~/.ai/AGENTS.md and any enabled harness.";
      type = types.nonEmptyStr;
    };

    agentsMd = mkOption {
      description = "Contents of ~/.ai/AGENTS.md.";
      type = types.lines;
      default = builtins.readFile ./AGENTS.md;
      defaultText = lib.literalExpression "the contents of ./AGENTS.md";
    };

    claude.enable = mkEnableOption "Claude Code, generically, via home-manager (no gateway/API key wiring)";

    pi = {
      enable = mkEnableOption "Pi, the AI coding agent harness (pi.dev)";
      package = mkPackageOption pkgs "pi" { };
    };

    notifications = {
      claudePush.enable = mkEnableOption "Claude Code's own mobile push when it needs input (Claude only, needs the mobile app linked)";

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
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.etc."mm-ai/AGENTS.md".text = cfg.agentsMd;

      systemd.tmpfiles.rules = [
        "d /home/${cfg.username}/.ai 0755 ${cfg.username} users -"
        "L+ /home/${cfg.username}/.ai/AGENTS.md - - - - /etc/mm-ai/AGENTS.md"
      ];
    })

    (mkIf cfg.claude.enable {
      home-manager.users.${cfg.username}.programs.claude-code = {
        enable = true;
        settings = lib.recursiveUpdate (lib.optionalAttrs cfg.notifications.claudePush.enable {
          inputNeededNotifEnabled = true;
        }) (lib.optionalAttrs scriptNotifyEnabled {
          hooks.Notification = [
            { hooks = [ { type = "command"; command = ''${notifyScript} "Claude needs your input" >/dev/null 2>&1 || true''; } ]; }
          ];
          hooks.Stop = [
            { hooks = [ { type = "command"; command = ''${notifyScript} "Claude finished" >/dev/null 2>&1 || true''; } ]; }
          ];
        });
      };
    })

    (mkIf cfg.pi.enable {
      environment.systemPackages = [ (if scriptNotifyEnabled then piWithNotify else cfg.pi.package) ];
    })
  ];
}
