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
    types
    ;
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
        inherit (cfg) username;
      };
    })

    (mkIf cfg.pi.enable {
      mm.pi = {
        enable = true;
        inherit (cfg) username;
      };
    })
  ];
}
