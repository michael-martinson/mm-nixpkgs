/*
  One default module that imports every module.nix below this folder, at any
  depth. To add a module, add a folder with a module.nix. Nothing else changes.

  Each module sets its options under a path that matches its folder. For example,
  modules/aws/module.nix owns mm.aws. A module must do nothing until it is
  enabled, so put its settings under `mkIf cfg.enable`.
*/
inputs: {
  default = {
    imports = inputs.self.library.modulesFromDirectoryRecursive ./.;
  };
}
