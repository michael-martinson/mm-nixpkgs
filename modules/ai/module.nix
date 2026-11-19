/*
  Shared AI agent setup for one user:

  - mm.ai.enable writes ./AGENTS.md to ~/.ai/AGENTS.md, then symlinks it into
    every agent tool's own global-instructions spot, so the same rules apply
    regardless of which tool(s) are actually installed (by this module, by
    mm.anduril.*, or anything else) - that is independent of mm.ai.claude/
    mm.ai.pi below. Confirmed by reading each tool's own source/docs, except
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

  - mm.ai.claude.enable / mm.ai.pi.enable just turn on mm.claude / mm.pi
    (their own modules, each independently usable) for mm.ai.username, with
    mm.ai.notifications applied. Set mm.claude/mm.pi directly instead if you
    want a different username or notification settings per tool. claude
    needs home-manager declared, same caveat as mm.claude itself.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption mkOption types;
  inherit (pkgs.myLibrary) notificationOptions;
  cfg = config.mm.ai;
in
{
  options.mm.ai = {
    enable = mkEnableOption "shared AI agent rules in ~/.ai/AGENTS.md";

    username = mkOption {
      description = "The user that gets ~/.ai/AGENTS.md and any harness turned on below.";
      type = types.nonEmptyStr;
    };

    agentsMd = mkOption {
      description = "Contents of ~/.ai/AGENTS.md.";
      type = types.lines;
      default = builtins.readFile ./AGENTS.md;
      defaultText = lib.literalExpression "the contents of ./AGENTS.md";
    };

    claude.enable = mkEnableOption "mm.claude for mm.ai.username (see modules/claude)";
    pi.enable = mkEnableOption "mm.pi for mm.ai.username (see modules/pi)";

    notifications = notificationOptions { withClaudePush = true; };
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
      mm.claude = {
        enable = true;
        inherit (cfg) username notifications;
      };
    })

    (mkIf cfg.pi.enable {
      mm.pi = {
        enable = true;
        inherit (cfg) username;
        notifications = removeAttrs cfg.notifications [ "claudePush" ];
      };
    })
  ];
}
