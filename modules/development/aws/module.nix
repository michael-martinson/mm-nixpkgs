{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.mm.dev.aws;
in
{
  options.mm.dev.aws = {
    enable = mkEnableOption "AWS tools";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      awscli2
      amazon-ecr-credential-helper
    ];
  };
}
