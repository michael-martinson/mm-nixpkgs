{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.mm.gaming;
in
{
  options.mm.gaming = {
    enable = mkEnableOption "enable gaming setup";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Game Launchers

      users.users.${config.mm.user.username}.packages = with pkgs; [
        wine
        mangohud
        protonup-qt
        bottles
        heroic
      ];

      programs = {
        steam = {
          enable = true;
          remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
          dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
          localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
          gamescopeSession.enable = true;
        };
        gamemode.enable = true;
      };
    }
  ]);
}
