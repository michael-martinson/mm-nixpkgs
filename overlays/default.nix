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

  localOverlays = composeManyExtensions (
    map (f: import ./${f}) (
      builtins.attrNames (
        filterAttrs (f: t: t == "regular" && f != "default.nix" && !(builtins.elem f disabledOverlays)) (
          builtins.readDir ./.
        )
      )
    )
  );

  # Adds pkgs.pi, built from ../packages/pi (our own derivation - see its
  # module.nix comment for why not upstream's flake).
  pi = final: prev: {
    pi = final.callPackage ../packages/pi/package.nix { };
  };

  default = composeManyExtensions [
    localOverlays
    library
    pi
  ];
in
{
  inherit default;
}
