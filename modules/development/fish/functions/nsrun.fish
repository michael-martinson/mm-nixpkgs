function nsrun
    if test (count $argv) -lt 2
        echo "Example usage: nsrun wget 'wget https://url.com'"
        return
    end

    set pkgs $argv[1..-2]
    set command $argv[(count $argv)]

    nix-shell -p $pkgs --run $command
end
