final: prev: {
  # Override neovim with my specific configs
  neovim = prev.neovim.override {
    configure = {
      packages.myVimPackage = with prev.vimPlugins; {
        start = [
          LazyVim
        ];
      };
      customLuaRC = builtins.readFile ./neovim-luarc.lua;
    };
  };
}
