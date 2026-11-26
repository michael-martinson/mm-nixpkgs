{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    mkMerge
    genAttrs
    ;
  cfg = config.mm.secrets;
in
{
  options.mm.secrets = with types; {
    enable = mkEnableOption "Secret Management";
    sops-file = mkOption {
      type = path;
      description = "The sops file containing your secrets";
    };
    sshKeyPaths = mkOption {
      type = listOf str;
    };
    keys = mkOption {
      type = listOf str;
      description = "List of secrets to use from ${cfg.sops-file}";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops = {
        # This will add secrets.yml to the nix store
        # You can avoid this by adding a string to the full path instead, i.e.
        # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
        defaultSopsFile = cfg.sops-file;
        age.sshKeyPaths = cfg.sshKeyPaths;
        secrets = genAttrs cfg.keys (_: { });
      };
    }
  ]);
}
