inputs:
inputs.self.library.defaultSystems (
  system:
  let
    pkgs = inputs.self.legacyPackages.${system};

    inherit (pkgs.myLibrary) defaultShellPackages fishShellInit;
  in
  {
    fish = pkgs.mkShell {
      packages = with pkgs; [ fish ] ++ (defaultShellPackages pkgs);
      shellHook = ''
        # Create temporary XDG config directory with unique name
        DEVSHELL_XDG="$TMPDIR/.config"
        mkdir -p "$DEVSHELL_XDG"

        # Symlink all existing XDG configs to preserve other app configurations
        if [ -d "$HOME/.config" ]; then
          for item in "$HOME/.config"/*; do
            [ -e "$item" ] && ln -sf "$item" "$DEVSHELL_XDG/"
          done
        fi

        # Remove fish symlink if it exists and create actual directory
        rm -f "$DEVSHELL_XDG/fish"
        mkdir -p "$DEVSHELL_XDG/fish"

        # Write custom fish configuration
        cat > "$DEVSHELL_XDG/fish/config.fish" << 'EOF'
        ${fishShellInit}
        EOF

        # Point to our custom XDG config directory
        export XDG_CONFIG_HOME="$DEVSHELL_XDG"

        exec fish
      '';
    };
  }
)
