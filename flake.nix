{
  description = "Michael Martinson's common Nix library, overlays, and modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = inputs: {
    library = import ./library inputs;
    devShells = import ./dev-shells inputs;
    legacyPackages = import ./legacy-packages inputs;
    overlays = import ./overlays inputs;
    nixosModules = import ./modules inputs;
  };
}
