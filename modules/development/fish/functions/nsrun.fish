function nsrun
    if test (count $argv) -lt 2
        echo "Example usage: nsrun wget 'wget https://url.com'"
        return
    end

    set -l pkgs $argv[1..-2]
    set -l command $argv[(count $argv)]

    nix-shell -p $pkgs --run $command
end
