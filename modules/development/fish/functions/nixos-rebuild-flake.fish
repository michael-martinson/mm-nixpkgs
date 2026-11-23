function nixos-rebuild-flake
    set -l type $argv[1]
    set -e argv[1]
    set -l config $argv[2]
    set -e argv[2]
    if test -z "$type"; or test -z "$config"
        echo "Usage: nixos-rebuild-flake {test|switch|boot} {nixos-configuration name}" >&2
        return 2
    end

    nixos-rebuild "$type" --flake ".#$config" $argv
end
