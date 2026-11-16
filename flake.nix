{
  description = "Michael Martinson's common Nix library, overlays, and modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "github:DeterminateSystems/determinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    library = import ./library inputs;
    devShells = import ./dev-shells inputs;
    legacyPackages = import ./legacy-packages inputs;
    overlays = import ./overlays inputs;
    nixosModules = (import ./modules inputs) // {
      # Re-exported so a consumer does not need its own input just to use
      # these. Neither is turned on by anything else here.
      homeManager = inputs.home-manager.nixosModules.home-manager;
      determinate = inputs.determinate.nixosModules.default;
    };
  };
}
