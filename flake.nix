{
  description = "Michael Martinson's common Nix library, overlays, and modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=26.05";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi = {
      url = "github:earendil-works/pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
