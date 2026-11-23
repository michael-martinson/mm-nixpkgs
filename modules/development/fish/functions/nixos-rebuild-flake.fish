function nixos-rebuild-flake
    set -l type $argv[1]
    set -e argv[1]
    if test -z "$type"
        echo "Usage: nixos-rebuild-flake {test|switch|boot}" >&2
        return 2
    end

    set -l config $argv[2]
    set -e argv[2]
    if test -z "$config"
        set -l config (hostname)
        echo "Using hostname for config: $config"
    end

    nixos-rebuild "$type" --flake ".#$config" $argv
end
