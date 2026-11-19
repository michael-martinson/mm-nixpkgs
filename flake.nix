{
  description = "Michael Martinson's common Nix library, overlays, and modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pi (pi.dev): an AI coding agent harness. Builds from source, with its
    # own nixpkgs pin (it also needs a separate nixpkgs for x86_64-darwin,
    # since nixpkgs unstable dropped Intel macOS) - not followed to this
    # repo's nixpkgs, the same way anduril-teleport/anduril-authorization in
    # mm-nixos-anduril keep their own pins instead of floating with ours.
    pi.url = "github:earendil-works/pi/stable";
  };

  outputs = inputs: {
    library = import ./library inputs;
    devShells = import ./dev-shells inputs;
    legacyPackages = import ./legacy-packages inputs;
    overlays = import ./overlays inputs;
    nixosModules = (import ./modules inputs) // {
      # Re-exported so a consumer does not need its own home-manager input
      # just to use this. Not turned on by anything else here.
      homeManager = inputs.home-manager.nixosModules.home-manager;
    };
  };
}
