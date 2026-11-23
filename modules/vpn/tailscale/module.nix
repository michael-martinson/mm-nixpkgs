# https://nixos.wiki/wiki/Tailscale
{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkMerge
    ;
  cfg = config.mm.tailscale;
in
{
  options.mm.tailscale = {
    enable = mkEnableOption "Tailscale VPN";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.tailscale = {
        enable = true;
      };
    }
  ]);
}
