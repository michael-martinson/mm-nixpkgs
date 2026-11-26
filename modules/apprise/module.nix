{
  pkgs,
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
  cfg = config.mm.apprise;
in
{
  options.mm.apprise = with types; {
    enable = mkEnableOption "Common Apprise Configuration";
    user = mkOption {
      type = str;
      default = config.defaults.primaryUser;
    };
    urls = mkOption {
      type = listOf (submodule {
        url = mkOption {
          type = str;
        };
        tags = mkOption {
          type = listOf str;
        };
      });
      description = "List of apprise to use from ${cfg.sops-file}";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      users.users.${cfg.user}.packages = with pkgs; [
        apprise
      ];

      sops.templates."apprise-config" = {
        owner = cfg.user;
        path = "${config.users.users.${cfg.user}.home}/.apprise.yaml";
        content = builtins.toJSON {
          urls = map (urls: {
            "${urls.url}" = {
              tag = urls.tags;
            };
          }) cfg.urls;
        };
      };
    }
  ]);
}
