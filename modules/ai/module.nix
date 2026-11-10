/*
  Shared AI agent rules. Writes ./AGENTS.md to ~/.ai/AGENTS.md for the given
  user, so every machine that enables this module gets the same agent rules.
  Plain NixOS, no home-manager required.
*/
{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.mm.ai;
in
{
  options.mm.ai = {
    enable = mkEnableOption "shared AI agent rules in ~/.ai/AGENTS.md";

    username = mkOption {
      description = "The user that gets ~/.ai/AGENTS.md.";
      type = types.nonEmptyStr;
    };

    agentsMd = mkOption {
      description = "Contents of ~/.ai/AGENTS.md.";
      type = types.lines;
      default = builtins.readFile ./AGENTS.md;
      defaultText = lib.literalExpression "the contents of ./AGENTS.md";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."mm-ai/AGENTS.md".text = cfg.agentsMd;

    systemd.tmpfiles.rules = [
      "d /home/${cfg.username}/.ai 0755 ${cfg.username} users -"
      "L+ /home/${cfg.username}/.ai/AGENTS.md - - - - /etc/mm-ai/AGENTS.md"
    ];
  };
}
