function ns --wraps='nix-shell -p' --description 'alias ns nix-shell -p'
    nix-shell -p $argv
end
