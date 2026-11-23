/*
  neovim with LazyVim and a custom Lua config (./neovim-luarc.lua), as the
  package `pkgs.neovim` resolves to everywhere - via an overlay this module
  contributes itself, gated on enable, rather than one that always applies.

  Standalone: set mm.dev.neovim.enable directly. Or let mm.user.enable turn
  this on for you (mkDefault, so setting mm.dev.neovim.enable yourself still
  wins).
*/
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.mm.dev.neovim;
in
{
  options.mm.dev.neovim = {
    enable = mkEnableOption "neovim with LazyVim and a custom Lua config";

    luaRC = mkOption {
      description = "customLuaRC contents for neovim.";
      type = types.lines;
      default = builtins.readFile ./neovim-luarc.lua;
      defaultText = lib.literalExpression "the contents of ./neovim-luarc.lua";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        neovim = prev.neovim.override {
          configure = {
            packages.myVimPackage = with prev.vimPlugins; {
              start = [
                LazyVim
              ];
            };
            customLuaRC = cfg.luaRC;
          };
        };
      })
    ];

    environment.variables.EDITOR = "nvim";
  };
}
