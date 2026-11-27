{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.mm.user.michael;

  username = "michael";
in
{
  options.mm.user.michael = {
    enable = mkEnableOption "the michael user";
  };

  config = mkIf cfg.enable {
    mm = {
      user = {
        enable = true;
        inherit username;
        email = "micmar.23@zohomail.com";
        fullName = "Michael";
        gitUserName = "micmar.23";
        homeManager.enable = true;
      };

      apprise = {
        enable = true;
        user = username;
        urls =
          [ ]
          ++ lib.optionals (builtins.hasAttr "discord_webhook" config.sops.secrets) [
            {
              url = config.sops.placeholder.discord_webhook;
              tags = [
                "discord"
                "pi"
              ];
            }
          ];
      };
    };
  };
}
