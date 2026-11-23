function nix-diff-current
    set -l config $argv[1]
    if test -z "$config"
        echo "Usage: nix-diff-current {nixos-configuration name}" >&2
        return 2
    end

    nix-diff \
        (readlink /run/current-system) \
        (nix build ".#nixosConfigurations.$config.config.system.build.toplevel" -v --print-out-paths)
end
