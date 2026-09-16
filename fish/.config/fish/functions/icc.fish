function icc
    set file (fzf \
        --preview 'bat --color=always -- {}' \
        --preview-window=right:60%)

    if test -n "$file"
        cat -- "$file" | wl-copy
    end
end
