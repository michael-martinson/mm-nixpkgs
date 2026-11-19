/*
  Shared AI agent setup for one user:

  - mm.ai.enable writes ./AGENTS.md to ~/.ai/AGENTS.md, then symlinks it into
    every agent tool's own global-instructions spot, so the same rules apply
    regardless of which tool(s) are actually installed (by this module, by
    mm.anduril.*, or anything else) - that is independent of mm.ai.claude/
    mm.ai.pi below, which only control whether this module installs the
    tool itself. Confirmed by reading each tool's own source/docs, except
    Codex (see its entry below):
      ~/.claude/CLAUDE.md               Claude Code
      ~/.codex/AGENTS.md                Codex
      ~/.config/opencode/AGENTS.md      OpenCode (which also already checks
                                         ~/.claude/CLAUDE.md itself, so the
                                         two can double up there - harmless,
                                         just repeats the same short file)
      ~/.pi/agent/AGENTS.md             Pi
    Codex's path is inferred, not directly observed: its binary contains
    the literal string "Failed to read global AGENTS.md instructions from
    `", proving the feature exists, and ~/.codex is its documented
    CODEX_HOME default - but tracing an actual run to see the exact path
    it probed led to a real, unintended request to the OpenAI API, so that
    was stopped short rather than pushed further to pin down one path.
    Plain NixOS, no home-manager required for this part.
  - mm.ai.claude.enable and mm.ai.pi.enable turn on Claude Code and/or Pi
    (pi.dev), independently. claude needs home-manager (for example
    inputs.mm-nixpkgs.nixosModules.homeManager) - home-manager.* must be
    declared in the system even if you never enable mm.ai.claude, the same
    way mm.secrets needs sops-nix declared. This is a GENERIC setup: no
    gateway, no API key wiring. A consumer with its own gateway-specific
    Claude Code module (mm.anduril.claude-code in mm-nixos-anduril) should
    use that instead of mm.ai.claude - do not enable both, they both try to
    set home-manager.users.<username>.programs.claude-code.
  - mm.ai.pi.package is our own build (../../packages/pi), from the npm
    registry, not upstream's flake - that fetches a model catalog from
    pi.dev at build time, which this network blocks. No home-manager, no
    gateway wiring, plain NixOS.

  - mm.ai.notifications fires one or more backends when a harness is done
    or needs input: Claude's own mobile push (claude only), ntfy, Pushover,
    or an arbitrary command.
    - Claude: its real Notification/Stop hooks.
    - Pi: a real Pi extension (verified against the actual package: its
      docs, type definitions, and the official examples/extensions/notify.ts
      it ships - see packages/pi/package.nix for how it is packaged), dropped
      into ~/.pi/agent/extensions/ where Pi auto-discovers it, listening for
      the agent_settled ("done", including "ready for your next message")
      and ui_prompt_start ("a blocking extension UI prompt is waiting")
      events.
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

  # A real Pi extension (see module header). jiti (Pi's own TS loader)
  # strips types at load time, so no type import and no build step needed.
  piNotifyExtension = ''
    import { execFile } from "node:child_process";

    function notify(message) {
      execFile(${builtins.toJSON "${notifyScript}"}, [message], () => {});
    }

    export default function (pi) {
      pi.on("agent_settled", async () => notify("Pi finished"));
      pi.on("ui_prompt_start", async () => notify("Pi needs your input"));
    }
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

        "d /home/${cfg.username}/.claude 0755 ${cfg.username} users -"
        "L+ /home/${cfg.username}/.claude/CLAUDE.md - - - - /etc/mm-ai/AGENTS.md"

        "d /home/${cfg.username}/.codex 0755 ${cfg.username} users -"
        "L+ /home/${cfg.username}/.codex/AGENTS.md - - - - /etc/mm-ai/AGENTS.md"

        "d /home/${cfg.username}/.config 0755 ${cfg.username} users -"
        "d /home/${cfg.username}/.config/opencode 0755 ${cfg.username} users -"
        "L+ /home/${cfg.username}/.config/opencode/AGENTS.md - - - - /etc/mm-ai/AGENTS.md"

        "d /home/${cfg.username}/.pi 0755 ${cfg.username} users -"
        "d /home/${cfg.username}/.pi/agent 0755 ${cfg.username} users -"
        "L+ /home/${cfg.username}/.pi/agent/AGENTS.md - - - - /etc/mm-ai/AGENTS.md"
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

    (mkIf cfg.pi.enable (mkMerge [
      { environment.systemPackages = [ cfg.pi.package ]; }
      (mkIf scriptNotifyEnabled {
        environment.etc."mm-ai/pi-notify.ts".text = piNotifyExtension;

        systemd.tmpfiles.rules = [
          "d /home/${cfg.username}/.pi 0755 ${cfg.username} users -"
          "d /home/${cfg.username}/.pi/agent 0755 ${cfg.username} users -"
          "d /home/${cfg.username}/.pi/agent/extensions 0755 ${cfg.username} users -"
          "L+ /home/${cfg.username}/.pi/agent/extensions/mm-ai-notify.ts - - - - /etc/mm-ai/pi-notify.ts"
        ];
      })
    ]))
  ];
}
