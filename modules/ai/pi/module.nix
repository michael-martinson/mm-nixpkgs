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
    mkPackageOption
    types
    ;
  cfg = config.mm.pi;

  extensionNames = builtins.attrNames (builtins.readDir ./extensions);
in
{
  options.mm.pi = {
    enable = mkEnableOption "Pi, the AI coding agent harness (pi.dev)";

    username = mkOption {
      description = "The user that gets Pi.";
      type = types.nonEmptyStr;
    };

    package = mkPackageOption pkgs "pi" { };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    environment.etc = lib.listToAttrs (
      map (name: {
        name = "mm-pi/extensions/${name}";
        value.source = ./extensions/${name};
      }) extensionNames
    );

    systemd.tmpfiles.rules = [
      "d /home/${cfg.username}/.pi 0755 ${cfg.username} users -"
      "d /home/${cfg.username}/.pi/agent 0755 ${cfg.username} users -"
      "d /home/${cfg.username}/.pi/agent/extensions 0755 ${cfg.username} users -"
    ]
    ++ map (
      name:
      "L+ /home/${cfg.username}/.pi/agent/extensions/mm-${name} - - - - /etc/mm-pi/extensions/${name}"
    ) extensionNames;
  };
}
