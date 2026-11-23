/*
  The shared fish shell config (./fish-shell-init.fish): prompt, greeting,
  and right-prompt status. `programs.fish` is a system-wide NixOS option,
  not per-user, so there is no username here - anyone using fish on the
  machine gets this shellInit.

  Standalone: set mm.dev.fish.enable directly. Or let mm.user.enable turn this
  on for you (mkDefault, so setting mm.dev.fish.enable yourself still wins).
*/
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    mkMerge
    ;
  cfg = config.mm.dev.fish;
in
{
  options.mm.dev.fish = {
    enable = mkEnableOption "the shared fish shell config";

    shellInit = mkOption {
      description = "fish shellInit contents.";
      type = types.lines;
      default = builtins.readFile ./fish-shell-init.fish;
      defaultText = lib.literalExpression "the contents of ./fish-shell-init.fish";
    };

    useHomeManager = mkEnableOption "use home manager to set fish configs";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.fish = {
        enable = true;
        shellInit = cfg.shellInit;
      };
    }
    (mkIf cfg.useHomeManager {
      xdg.configFile."fish/functions".source = ./functions;
    })
    (mkIf (!cfg.useHomeManager) {

    })
  ]);
}
