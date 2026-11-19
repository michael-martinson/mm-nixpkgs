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

  default = composeManyExtensions [
    localOverlays
    library
    # Adds pkgs.pi. Upstream ships this overlay itself; reuse it instead of
    # writing our own package derivation.
    inputs.pi.overlays.default
  ];
in
{
  inherit default;
}
