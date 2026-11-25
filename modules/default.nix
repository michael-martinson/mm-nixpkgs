/*
  Each top-level folder with a module.nix is a module, named after that folder
  (`aws`, `secrets`, `ai`, ...). Pick individual modules to avoid pulling in
  one you do not want (for example `secrets`, which needs sops-nix), or use
  `default` to import every module.nix below this folder, at any depth.

  Each module sets its options under a path that matches its folder. For example,
  modules/aws/module.nix owns mm.dev.aws. A module must do nothing until it is
  enabled, so put its settings under `mkIf cfg.enable`.
*/
inputs:
let
  inherit (inputs.nixpkgs) lib;
  inherit (lib.attrsets) filterAttrs;

  topLevelModules = lib.genAttrs (builtins.attrNames (
    filterAttrs (name: type: type == "directory") (builtins.readDir ./.)
  )) (name: import ./${name}/module.nix);
in
topLevelModules
// {
  default = {
    imports = (inputs.self.library.modulesFromDirectoryRecursive ./.) ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.default
    ];
  };
}
