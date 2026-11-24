function nix-diff-current
    set config $argv[1]
    set -e argv[1]
    if test -z "$config"
        set config (hostname)
        echo "Using hostname for config: $config"
    end

    nix-diff \
        (readlink /run/current-system) \
        (nix build .#nixosConfigurations.$config.config.system.build.toplevel -v --print-out-paths) \
        $argv
end
