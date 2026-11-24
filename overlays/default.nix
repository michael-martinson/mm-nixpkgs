inputs:
let
  inherit (inputs.nixpkgs) lib;

  inherit (lib.fixedPoints) composeManyExtensions;

  inherit (lib.attrsets) filterAttrs;

  library = final: prev: {
    myLibrary = inputs.self.library;
  };

  disabledOverlays = [
  ];

  # Only *.nix files are overlays - a sibling file (a .lua config read via
  # builtins.readFile, say) is not one to import.
  localOverlays = composeManyExtensions (
    map (f: import ./${f}) (
      builtins.attrNames (
        filterAttrs (
          f: t:
          t == "regular"
          && f != "default.nix"
          && lib.hasSuffix ".nix" f
          && !(builtins.elem f disabledOverlays)
        ) (builtins.readDir ./.)
      )
    )
  );

  # Exposes every ../packages/<name>/package.nix as pkgs.<name> - add a
  # package by adding a folder, nothing to wire up here.
  packages =
    final: _prev:
    lib.filesystem.packagesFromDirectoryRecursive {
      callPackage = final.callPackage;
      directory = ../packages;
    };

  default = composeManyExtensions [
    localOverlays
    library
    packages
    inputs.pi.overlays.default
  ];
in
{
  inherit default;
}
