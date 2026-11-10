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
        # This will automatically import SSH keys as age keys
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets = genAttrs cfg.keys (_: { });
      };
    }
  ]);
}
