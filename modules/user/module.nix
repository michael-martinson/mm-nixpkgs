/*
  A common desktop user: the account itself, fonts, fish, neovim, direnv,
  nix-ld, git identity, and the shared dev tool list. One user per
  machine, name set by `username`:

    mm.user = {
      enable = true;
      username = "mmartinson";
      email = "mmartinson@example.com";
    };

  Optionally also a home-manager profile for that user. This needs the
  home-manager NixOS module imported (for example
  inputs.mm-nixpkgs.nixosModules.homeManager):

    mm.user.homeManager = {
      enable = true;
      extraConfig.home.packages = [ ... ];
    };
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    mkDefault
    types
    ;
  inherit (pkgs.myLibrary) defaultShellPackages;

  cfg = config.mm.user;
in
{
  options.mm.user = {
    enable = mkEnableOption "the common desktop user";

    username = mkOption {
      description = "The Linux username.";
      type = types.nonEmptyStr;
    };

    fullName = mkOption {
      description = "Account description.";
      type = types.str;
      default = cfg.username;
    };

    email = mkOption {
      description = "git user.email for this user.";
      type = types.str;
    };

    gitUserName = mkOption {
      description = "git user.name for this user.";
      type = types.str;
      default = cfg.username;
    };

    extraGroups = mkOption {
      description = "Extra groups for the user account.";
      type = types.listOf types.str;
      default = [
        "networkmanager"
        "wheel"
      ];
    };

    packages = mkOption {
      description = "Extra system packages for this user, on top of defaultShellPackages.";
      type = types.listOf types.package;
      default = [ ];
    };

    homeManager = {
      enable = mkEnableOption "a home-manager profile for this user";

      # No default here: deferring to config.system.stateVersion as a default
      # has to happen in `config` below, not in the option declaration, or
      # the module system deadlocks on itself.
      stateVersion = mkOption {
        description = "home.stateVersion for this user. Defaults to config.system.stateVersion.";
        type = types.nullOr types.str;
        default = null;
      };

      extraConfig = mkOption {
        description = "Extra home-manager config, merged into home-manager.users.<username>. Use this to share a home structure, packages, dotfiles, and so on.";
        type = types.attrs;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.agave
      ];

      programs.direnv.enable = true;
      mm.fish.enable = mkDefault true;
      mm.neovim.enable = mkDefault true;
      # This is required for treesitter to work in lazyvim
      programs.nix-ld.enable = true;

      users.users.${cfg.username} = {
        isNormalUser = true;
        description = cfg.fullName;
        extraGroups = cfg.extraGroups;
        shell = pkgs.fish;
        packages = cfg.packages ++ (defaultShellPackages pkgs);
      };

      programs.git = {
        enable = true;
        config.user = {
          email = cfg.email;
          name = cfg.gitUserName;
        };
      };
    }
    (mkIf cfg.homeManager.enable {
      home-manager.useGlobalPkgs = mkDefault true;
      home-manager.useUserPackages = mkDefault true;
      home-manager.users.${cfg.username} = mkMerge [
        {
          home.stateVersion = mkDefault (
            if cfg.homeManager.stateVersion != null then
              cfg.homeManager.stateVersion
            else
              config.system.stateVersion
          );
        }
        cfg.homeManager.extraConfig
      ];
    })
  ]);
}
