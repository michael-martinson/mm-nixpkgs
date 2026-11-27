{
  config,
  lib,
  pkgs,
  inputs,
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
      description = "System packages for this user.";
      type = types.listOf types.package;
      default =
        with pkgs;
        (defaultShellPackages pkgs)
        ++ [
          wezterm
          bitwarden-desktop
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
          nextcloud-client
          hunspell # used for spellcheck with libreoffice
        ];
    };

    homeManager = {
      enable = mkEnableOption "a home-manager profile for this user";
      stateVersion = mkOption {
        description = "home.stateVersion for this user. Defaults to config.system.stateVersion.";
        type = types.nullOr types.str;
        default = null;
      };
      config = mkOption {
        description = "home-manager config, merged into home-manager.users.<username>.";
        type = types.attrs;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Nix settings
      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      nixpkgs.config.allowUnfree = true;

      # User setup
      users.users.${cfg.username} = {
        isNormalUser = true;
        description = cfg.fullName;
        extraGroups = cfg.extraGroups;
        shell = pkgs.fish;
        packages = cfg.packages ++ (defaultShellPackages pkgs);
      };

      # Dev setup
      mm.dev = {
        fish = {
          enable = mkDefault true;
          useHomeManager = mkDefault cfg.homeManager.enable;
        };
        neovim.enable = mkDefault true;
        aws.enable = mkDefault true;
      };

      programs.direnv.enable = true;

      programs.git = {
        enable = true;
        config.user = {
          email = cfg.email;
          name = cfg.gitUserName;
        };
      };

      mm.ai = {
        enable = true;
        username = cfg.username;
        pi.enable = true;
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
        cfg.homeManager.config
      ];
    })
  ]);
}
