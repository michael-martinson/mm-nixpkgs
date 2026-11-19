/*
  The shared fish shell config (../../library/fish-shell-init.fish):
  prompt, greeting, and right-prompt status. `programs.fish` is a
  system-wide NixOS option, not per-user, so there is no username here -
  anyone using fish on the machine gets this shellInit.

  Standalone: set mm.fish.enable directly. Or let mm.user.enable turn this
  on for you (mkDefault, so setting mm.fish.enable yourself still wins).
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (pkgs.myLibrary) fishShellInit;
  cfg = config.mm.fish;
in
{
  options.mm.fish.enable = mkEnableOption "the shared fish shell config";

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellInit = fishShellInit;
    };
  };
}
