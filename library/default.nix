inputs:
let
  inherit (inputs.nixpkgs) lib;

  inherit (lib.attrsets) genAttrs;
in
rec {
  # Paths of every module.nix below `directory`, at any depth.
  modulesFromDirectoryRecursive =
    directory:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = directory + "/${name}";
        in
        if type == "directory" then
          modulesFromDirectoryRecursive path
        else if type == "regular" && name == "module.nix" then
          [ path ]
        else
          [ ]
      ) (builtins.readDir directory)
    );

  # Function that takes a function (system -> Any) and generates an Attrset
  defaultSystems = genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # Packages that should be available for any shell
  defaultShellPackages =
    pkgs: with pkgs; [
      zellij
      git

      # terminal utils
      usbutils
      tree
      jq
      wget
      dig

      # neovim - LazyVim config set by mm.dev.neovim
      neovim
      # lazy vim deps
      fd
      ripgrep
      lazygit
      fzf
      python3
      nodejs
      gcc

      # nix dev
      nixd
      nixfmt
      nix-diff

      # rust dev
      rustc
      cargo
      rust-analyzer
    ];
}
