{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkMerge
    ;
  cfg = config.mm.display-link;
in
{
  options.mm.display-link = {
    enable = mkEnableOption "Secret Management";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        # Display link monitors over usb
        displaylink
      ];

      services.xserver.videoDrivers = [
        "displaylink"
        "modesetting"
      ];
    }
  ]);
}
