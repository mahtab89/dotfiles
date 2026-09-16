function cdf
    set dir (fd --type d --hidden --exclude .git | fzf \
        --preview 'eza --tree --level=2 --color=always -- {}')

    if test -n "$dir"
        cd "$dir"
    end
end

# Fuzzy change directory from home
