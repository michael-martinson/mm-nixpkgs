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

      # neovim - configuratios set in overlay
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

      # rust dev
      rustc
      cargo
      rust-analyzer
    ];

  fishShellInit = ''
    function fish_greeting
      string join "" -- "Welcome to the " (set_color brred) "Fantastic " (set_color brgreen) "Fancy "  (set_color brblue) "Fish " (set_color brcyan) "Shell"
    end

    function fish_prompt
      set -g __fish_git_prompt_color blue
      set -g __fish_git_prompt_showcolorhints true
      set -g __fish_git_prompt_color_branch blue

      set -g __fish_git_prompt_showdirtystate true
      set -g __fish_git_prompt_showuntrackedfiles true
      set -g __fish_git_prompt_showupstream auto

      if set -q SHELL_NAME
        set_color -i magenta
        echo -n "[$SHELL_NAME] "
      end
      set_color normal
      echo -n (prompt_pwd --full-length-dirs=2)
      echo -n (fish_git_prompt)
      set_color --bold bryellow
      echo ""
      echo -n "♱ "
      set_color normal
    end

    function fish_right_prompt
      set -l last_status $status

      # Prompt status only if its not 0
      set -l stat
      if test $last_status -ne 0
          set stat (set_color red)"[$last_status]"(set_color normal)
      end

      echo -n "$stat"
    end
  '';
}
