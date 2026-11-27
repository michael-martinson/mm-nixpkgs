{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    ;
  cfg = config.mm.claude;
in
{
  options.mm.claude = {
    enable = mkEnableOption "Claude Code, generically, via home-manager (no gateway/API key wiring)";

    username = mkOption {
      description = "The user that gets Claude Code.";
      type = types.nonEmptyStr;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${cfg.username}.programs.claude-code = {
      enable = true;
    };
  };
}
